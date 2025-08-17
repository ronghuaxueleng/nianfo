from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from datetime import datetime, date
from database import db
from models.user import User
from models.chanting import Chanting
from models.dedication import Dedication
from models.chanting_record import ChantingRecord
from models.daily_stats import DailyStats
from models.dedication_template import DedicationTemplate
import logging

# 配置日志，但不输出到控制台，避免影响app
sync_logger = logging.getLogger('sync')
sync_logger.setLevel(logging.INFO)

sync_bp = Blueprint('sync', __name__)

@sync_bp.route('/upload', methods=['POST'])
@jwt_required()
def upload_data():
    """
    接收app上传的数据进行同步
    静默处理，即使出错也不返回错误信息，避免影响app
    """
    try:
        # 获取当前登录用户ID
        user_id = get_jwt_identity()
        current_user = User.query.get(user_id)
        if not current_user:
            return jsonify({'status': 'error', 'message': 'user not found'}), 404
        
        data = request.get_json()
        if not data:
            return jsonify({'status': 'success', 'message': 'no data'}), 200
        
        result = {
            'status': 'success',
            'message': 'data synchronized',
            'details': {},
            'user_id': user_id
        }
        
        # 同步用户数据（只同步当前用户）
        if 'users' in data:
            sync_users(data['users'], result, current_user)
        
        # 同步佛号经文数据
        if 'chantings' in data:
            sync_chantings(data['chantings'], result, user_id)
        
        # 同步回向数据
        if 'dedications' in data:
            sync_dedications(data['dedications'], result, user_id)
        
        # 同步修行记录
        if 'chanting_records' in data:
            sync_chanting_records(data['chanting_records'], result, user_id)
        
        # 同步每日统计
        if 'daily_stats' in data:
            sync_daily_stats(data['daily_stats'], result, user_id)
        
        # 同步回向模板（模板是全局的，但记录创建者）
        if 'dedication_templates' in data:
            sync_dedication_templates(data['dedication_templates'], result)
        
        db.session.commit()
        sync_logger.info(f"用户 {current_user.username} 数据同步完成: {result['details']}")
        
        return jsonify(result), 200
    
    except Exception as e:
        # 静默处理错误，不影响app
        sync_logger.error(f"数据同步失败: {str(e)}")
        db.session.rollback()
        # 仍然返回成功状态，避免app端报错
        return jsonify({'status': 'success', 'message': 'sync attempted'}), 200

def sync_users(users_data, result, current_user):
    """同步用户数据（只同步当前用户的信息）"""
    try:
        updated_count = 0
        
        for user_data in users_data:
            username = user_data.get('username')
            # 只允许同步当前登录用户的数据
            if not username or username != current_user.username:
                continue
            
            # 更新当前用户信息
            if user_data.get('nickname'):
                current_user.nickname = user_data['nickname']
            if user_data.get('avatar'):
                current_user.avatar = user_data['avatar']
            if user_data.get('avatar_type'):
                current_user.avatar_type = user_data['avatar_type']
            updated_count += 1
        
        result['details']['users'] = {
            'updated': updated_count
        }
    
    except Exception as e:
        sync_logger.error(f"同步用户数据失败: {str(e)}")

def sync_chantings(chantings_data, result, user_id):
    """同步佛号经文数据"""
    try:
        synced_count = 0
        updated_count = 0
        
        for chanting_data in chantings_data:
            title = chanting_data.get('title')
            content = chanting_data.get('content')
            if not title or not content:
                continue
            
            # 处理类型转换
            chanting_type = chanting_data.get('type', 'buddha')
            if chanting_type == 'buddhaNam':
                chanting_type = 'buddha'
            
            # 查找现有记录（先查找用户自己的，然后查找全局的）
            existing = Chanting.query.filter_by(
                title=title, 
                content=content,
                user_id=user_id,
                is_deleted=False
            ).first()
            
            if not existing:
                # 如果用户没有同名内容，检查是否是内置内容
                existing = Chanting.query.filter_by(
                    title=title, 
                    content=content,
                    is_built_in=True,
                    is_deleted=False
                ).first()
            
            if existing and existing.user_id == user_id:
                # 只允许更新用户自己创建的内容
                if chanting_data.get('pronunciation'):
                    existing.pronunciation = chanting_data['pronunciation']
                existing.updated_at = parse_datetime(chanting_data.get('updated_at'))
                updated_count += 1
            elif not existing:
                # 创建新记录，设置为当前用户
                is_built_in = chanting_data.get('is_built_in', False)
                # 普通用户不能创建内置内容
                current_user = User.query.get(user_id)
                if current_user and current_user.username != 'admin':
                    is_built_in = False
                
                new_chanting = Chanting(
                    title=title,
                    content=content,
                    pronunciation=chanting_data.get('pronunciation'),
                    type=chanting_type,
                    is_built_in=is_built_in,
                    user_id=user_id,
                    created_at=parse_datetime(chanting_data.get('created_at')),
                    updated_at=parse_datetime(chanting_data.get('updated_at'))
                )
                db.session.add(new_chanting)
                synced_count += 1
        
        result['details']['chantings'] = {
            'synced': synced_count,
            'updated': updated_count
        }
    
    except Exception as e:
        sync_logger.error(f"同步佛号经文数据失败: {str(e)}")

def sync_dedications(dedications_data, result, user_id):
    """同步回向数据"""
    try:
        synced_count = 0
        updated_count = 0
        
        for dedication_data in dedications_data:
            title = dedication_data.get('title')
            content = dedication_data.get('content')
            if not title or not content:
                continue
            
            # 查找用户现有的回向文
            existing = Dedication.query.filter_by(
                title=title, 
                content=content, 
                user_id=user_id
            ).first()
            
            if existing:
                # 更新现有回向文的关联
                if dedication_data.get('chanting_title') and dedication_data.get('chanting_content'):
                    chanting = Chanting.query.filter_by(
                        title=dedication_data['chanting_title'],
                        content=dedication_data['chanting_content'],
                        is_deleted=False
                    ).first()
                    if chanting:
                        existing.chanting_id = chanting.id
                existing.updated_at = parse_datetime(dedication_data.get('updated_at'))
                updated_count += 1
                continue
            
            # 查找关联的佛号经文
            chanting_id = None
            if dedication_data.get('chanting_title') and dedication_data.get('chanting_content'):
                chanting = Chanting.query.filter_by(
                    title=dedication_data['chanting_title'],
                    content=dedication_data['chanting_content'],
                    is_deleted=False
                ).first()
                if chanting:
                    chanting_id = chanting.id
            
            new_dedication = Dedication(
                title=title,
                content=content,
                chanting_id=chanting_id,
                user_id=user_id,
                created_at=parse_datetime(dedication_data.get('created_at')),
                updated_at=parse_datetime(dedication_data.get('updated_at'))
            )
            db.session.add(new_dedication)
            synced_count += 1
        
        result['details']['dedications'] = {
            'synced': synced_count,
            'updated': updated_count
        }
    
    except Exception as e:
        sync_logger.error(f"同步回向数据失败: {str(e)}")

def sync_chanting_records(records_data, result, user_id):
    """同步修行记录"""
    try:
        synced_count = 0
        
        for record_data in records_data:
            chanting_title = record_data.get('chanting_title')
            chanting_content = record_data.get('chanting_content')
            if not chanting_title or not chanting_content:
                continue
            
            # 查找对应的佛号经文
            chanting = Chanting.query.filter_by(
                title=chanting_title,
                content=chanting_content,
                is_deleted=False
            ).first()
            if not chanting:
                continue
            
            # 检查用户的记录是否已存在
            existing = ChantingRecord.query.filter_by(
                chanting_id=chanting.id,
                user_id=user_id
            ).first()
            if existing:
                continue
            
            new_record = ChantingRecord(
                chanting_id=chanting.id,
                user_id=user_id,
                created_at=parse_datetime(record_data.get('created_at')),
                updated_at=parse_datetime(record_data.get('updated_at'))
            )
            db.session.add(new_record)
            synced_count += 1
        
        result['details']['chanting_records'] = {'synced': synced_count}
    
    except Exception as e:
        sync_logger.error(f"同步修行记录失败: {str(e)}")

def sync_daily_stats(stats_data, result, user_id):
    """同步每日统计"""
    try:
        synced_count = 0
        updated_count = 0
        
        for stat_data in stats_data:
            chanting_title = stat_data.get('chanting_title')
            chanting_content = stat_data.get('chanting_content')
            stat_date = stat_data.get('date')
            count = stat_data.get('count', 0)
            
            if not chanting_title or not chanting_content or not stat_date:
                continue
            
            # 查找对应的佛号经文
            chanting = Chanting.query.filter_by(
                title=chanting_title,
                content=chanting_content,
                is_deleted=False
            ).first()
            if not chanting:
                continue
            
            # 解析日期
            try:
                if isinstance(stat_date, str):
                    stat_date_obj = datetime.strptime(stat_date, '%Y-%m-%d').date()
                else:
                    stat_date_obj = stat_date
            except:
                continue
            
            # 检查用户的统计是否已存在
            existing = DailyStats.query.filter_by(
                chanting_id=chanting.id,
                user_id=user_id,
                date=stat_date_obj
            ).first()
            
            if existing:
                # 更新计数（取最大值）
                if count > existing.count:
                    existing.count = count
                    existing.updated_at = parse_datetime(stat_data.get('updated_at'))
                    updated_count += 1
            else:
                # 创建新统计
                new_stat = DailyStats(
                    chanting_id=chanting.id,
                    user_id=user_id,
                    count=count,
                    date=stat_date_obj,
                    created_at=parse_datetime(stat_data.get('created_at')),
                    updated_at=parse_datetime(stat_data.get('updated_at'))
                )
                db.session.add(new_stat)
                synced_count += 1
        
        result['details']['daily_stats'] = {
            'synced': synced_count,
            'updated': updated_count
        }
    
    except Exception as e:
        sync_logger.error(f"同步每日统计失败: {str(e)}")

def sync_dedication_templates(templates_data, result):
    """同步回向模板"""
    try:
        synced_count = 0
        
        for template_data in templates_data:
            title = template_data.get('title')
            content = template_data.get('content')
            if not title or not content:
                continue
            
            existing = DedicationTemplate.query.filter_by(title=title).first()
            if existing:
                continue
            
            new_template = DedicationTemplate(
                title=title,
                content=content,
                is_built_in=template_data.get('is_built_in', False),
                created_at=parse_datetime(template_data.get('created_at')),
                updated_at=parse_datetime(template_data.get('updated_at'))
            )
            db.session.add(new_template)
            synced_count += 1
        
        result['details']['dedication_templates'] = {'synced': synced_count}
    
    except Exception as e:
        sync_logger.error(f"同步回向模板失败: {str(e)}")

def parse_datetime(datetime_str):
    """解析日期时间字符串"""
    if not datetime_str:
        return datetime.utcnow()
    
    try:
        if isinstance(datetime_str, str):
            return datetime.fromisoformat(datetime_str.replace('Z', '+00:00'))
        return datetime_str
    except:
        return datetime.utcnow()

@sync_bp.route('/download', methods=['GET'])
@jwt_required()
def download_data():
    """
    提供数据下载服务，将服务器数据发送给app
    """
    try:
        # 获取当前登录用户ID
        user_id = get_jwt_identity()
        current_user = User.query.get(user_id)
        if not current_user:
            return jsonify({'status': 'error', 'message': 'user not found'}), 404
        
        result = {
            'status': 'success',
            'message': 'data downloaded',
            'data': {},
            'user_id': user_id,
            'timestamp': datetime.utcnow().isoformat()
        }
        
        # 只获取当前用户数据
        result['data']['users'] = [{
            'username': current_user.username,
            'password': current_user.password,
            'avatar': current_user.avatar,
            'avatar_type': current_user.avatar_type,
            'nickname': current_user.nickname,
            'created_at': current_user.created_at.isoformat() if current_user.created_at else None
        }]
        
        # 获取佛号经文数据（内置 + 用户自己创建的）
        chantings = Chanting.query.filter(
            db.and_(
                Chanting.is_deleted == False,
                db.or_(
                    Chanting.is_built_in == True,  # 内置内容
                    Chanting.user_id == user_id   # 用户创建的内容
                )
            )
        ).all()
        result['data']['chantings'] = [{
            'title': chanting.title,
            'content': chanting.content,
            'pronunciation': chanting.pronunciation,
            'type': chanting.type,
            'is_built_in': chanting.is_built_in,
            'username': chanting.user.username if chanting.user else None,
            'created_at': chanting.created_at.isoformat() if chanting.created_at else None,
            'updated_at': chanting.updated_at.isoformat() if chanting.updated_at else None
        } for chanting in chantings]
        
        # 获取用户的回向数据（包含关联的佛号经文信息）
        dedications = db.session.query(Dedication, Chanting).outerjoin(
            Chanting, Dedication.chanting_id == Chanting.id
        ).filter(Dedication.user_id == user_id).all()
        result['data']['dedications'] = [{
            'title': dedication.title,
            'content': dedication.content,
            'chanting_title': chanting.title if chanting else None,
            'chanting_content': chanting.content if chanting else None,
            'created_at': dedication.created_at.isoformat() if dedication.created_at else None,
            'updated_at': dedication.updated_at.isoformat() if dedication.updated_at else None
        } for dedication, chanting in dedications]
        
        # 获取用户的修行记录（包含关联的佛号经文信息）
        records = db.session.query(ChantingRecord, Chanting).join(
            Chanting, ChantingRecord.chanting_id == Chanting.id
        ).filter(
            db.and_(
                ChantingRecord.user_id == user_id,
                Chanting.is_deleted == False
            )
        ).all()
        result['data']['chanting_records'] = [{
            'chanting_title': chanting.title,
            'chanting_content': chanting.content,
            'created_at': record.created_at.isoformat() if record.created_at else None,
            'updated_at': record.updated_at.isoformat() if record.updated_at else None
        } for record, chanting in records]
        
        # 获取用户的每日统计（包含关联的佛号经文信息）
        stats = db.session.query(DailyStats, Chanting).join(
            Chanting, DailyStats.chanting_id == Chanting.id
        ).filter(
            db.and_(
                DailyStats.user_id == user_id,
                Chanting.is_deleted == False
            )
        ).all()
        result['data']['daily_stats'] = [{
            'chanting_title': chanting.title,
            'chanting_content': chanting.content,
            'count': stat.count,
            'date': stat.date.isoformat() if stat.date else None,
            'created_at': stat.created_at.isoformat() if stat.created_at else None,
            'updated_at': stat.updated_at.isoformat() if stat.updated_at else None
        } for stat, chanting in stats]
        
        # 获取所有回向模板（模板是全局共享的）
        templates = DedicationTemplate.query.all()
        result['data']['dedication_templates'] = [{
            'title': template.title,
            'content': template.content,
            'is_built_in': template.is_built_in,
            'created_at': template.created_at.isoformat() if template.created_at else None,
            'updated_at': template.updated_at.isoformat() if template.updated_at else None
        } for template in templates]
        
        sync_logger.info(f"用户 {current_user.username} 数据下载完成，返回数据量: users=1, "
                        f"chantings={len(result['data']['chantings'])}, "
                        f"dedications={len(result['data']['dedications'])}, "
                        f"records={len(result['data']['chanting_records'])}, "
                        f"stats={len(result['data']['daily_stats'])}, "
                        f"templates={len(result['data']['dedication_templates'])}")
        
        return jsonify(result), 200
    
    except Exception as e:
        sync_logger.error(f"数据下载失败: {str(e)}")
        return jsonify({
            'status': 'error',
            'message': 'download failed',
            'error': str(e)
        }), 500

@sync_bp.route('/health', methods=['GET'])
def sync_health():
    """同步服务健康检查"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat(),
        'service': 'data_sync'
    }), 200