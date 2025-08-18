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

# 配置日志输出到控制台以便调试
sync_logger = logging.getLogger('sync')
sync_logger.setLevel(logging.INFO)

# 添加控制台输出handler
if not sync_logger.handlers:
    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.INFO)
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    console_handler.setFormatter(formatter)
    sync_logger.addHandler(console_handler)

sync_bp = Blueprint('sync', __name__)

@sync_bp.route('/upload', methods=['POST'])
def upload_data():
    """
    接收app上传的数据进行同步
    静默处理，即使出错也不返回错误信息，避免影响app
    """
    try:
        sync_logger.info("=== 开始处理数据上传请求 ===")
        
        # 支持多种认证方式
        current_user = None
        user_id = None
        
        # 方式1：尝试JWT认证
        try:
            from flask_jwt_extended import verify_jwt_in_request
            verify_jwt_in_request()
            user_id = get_jwt_identity()
            current_user = User.query.get(user_id)
            sync_logger.info(f"JWT认证成功，用户ID: {user_id}")
        except Exception as e:
            # JWT认证失败，尝试其他方式
            sync_logger.info(f"JWT认证失败: {str(e)}")
            pass
        
        # 方式2：如果JWT失败，尝试请求体中的认证信息
        if not current_user:
            data = request.get_json() or {}
            auth_info = data.get('auth', {})
            username = auth_info.get('username')
            password = auth_info.get('password')
            
            sync_logger.info(f"尝试用户名密码认证，用户名: {username}, 密码长度: {len(password) if password else 0}")
            
            if username and password:
                from utils.crypto_utils import CryptoUtils
                user = User.query.filter_by(username=username, is_deleted=False).first()
                sync_logger.info(f"查找用户结果: {'找到用户' if user else '用户不存在'}")
                
                if user:
                    password_valid = CryptoUtils.verify_password(password, user.password)
                    sync_logger.info(f"密码验证结果: {'正确' if password_valid else '错误'}")
                    
                    if password_valid:
                        current_user = user
                        user_id = user.id
                        sync_logger.info(f"用户名密码认证成功，用户ID: {user_id}, 用户名: {username}")
                else:
                    # 用户不存在，尝试从app数据中创建用户
                    sync_logger.info("后台用户不存在，尝试从app数据中创建用户")
                    users_data = data.get('users', [])
                    sync_logger.info(f"app数据中的用户数量: {len(users_data)}")
                    
                    for i, user_data in enumerate(users_data):
                        sync_logger.info(f"检查第 {i+1} 个用户数据: {user_data.get('username')}")
                        if user_data.get('username') == username:
                            # 验证app中的密码是否与传入的密码匹配
                            app_password_hash = user_data.get('password')
                            sync_logger.info(f"找到匹配用户，app密码哈希长度: {len(app_password_hash) if app_password_hash else 0}")
                            sync_logger.info(f"认证密码: {password}")
                            sync_logger.info(f"app密码哈希: {app_password_hash}")
                            
                            if app_password_hash and CryptoUtils.verify_password(password, app_password_hash):
                                # 创建新用户
                                sync_logger.info(f"密码验证通过，创建新用户: {username}")
                                new_user = User(
                                    username=username,
                                    password=app_password_hash,  # 使用app中已哈希的密码
                                    avatar=user_data.get('avatar'),
                                    avatar_type=user_data.get('avatar_type', 'emoji'),
                                    nickname=user_data.get('nickname'),
                                    created_at=parse_datetime(user_data.get('created_at'))
                                )
                                db.session.add(new_user)
                                db.session.flush()  # 获取用户ID
                                current_user = new_user
                                user_id = new_user.id
                                sync_logger.info(f"新用户创建成功，用户ID: {user_id}, 用户名: {username}")
                                break
                            else:
                                sync_logger.warning(f"app数据中的密码与认证密码不匹配")
                                sync_logger.warning(f"密码验证失败: CryptoUtils.verify_password('{password}', '{app_password_hash}') = False")
                    else:
                        sync_logger.warning(f"在app数据中没有找到用户: {username}")
        
        # 如果所有认证方式都失败
        if not current_user:
            sync_logger.warning("所有认证方式都失败，返回认证失败")
            return jsonify({'status': 'success', 'message': 'authentication failed'}), 200
        
        data = request.get_json()
        if not data:
            sync_logger.warning("请求中没有数据")
            return jsonify({'status': 'success', 'message': 'no data'}), 200
        
        # 记录接收到的数据类型和数量
        data_summary = {}
        for key in ['users', 'chantings', 'dedications', 'chanting_records', 'daily_stats', 'dedication_templates']:
            if key in data:
                count = len(data[key]) if isinstance(data[key], list) else 1
                data_summary[key] = count
        
        sync_logger.info(f"接收到的数据概要: {data_summary}")
        
        result = {
            'status': 'success',
            'message': 'data synchronized',
            'details': {},
            'user_id': user_id
        }
        
        # 同步用户数据（只同步当前用户）
        if 'users' in data:
            sync_logger.info(f"开始同步用户数据，数量: {len(data['users'])}")
            sync_users(data['users'], result, current_user)
        
        # 同步佛号经文数据
        if 'chantings' in data:
            sync_logger.info(f"开始同步佛号经文数据，数量: {len(data['chantings'])}")
            sync_chantings(data['chantings'], result, user_id)
        
        # 同步回向数据
        if 'dedications' in data:
            sync_logger.info(f"开始同步回向数据，数量: {len(data['dedications'])}")
            sync_dedications(data['dedications'], result, user_id)
        
        # 同步修行记录
        if 'chanting_records' in data:
            sync_logger.info(f"开始同步修行记录，数量: {len(data['chanting_records'])}")
            sync_chanting_records(data['chanting_records'], result, user_id)
        
        # 同步每日统计
        if 'daily_stats' in data:
            sync_logger.info(f"开始同步每日统计，数量: {len(data['daily_stats'])}")
            sync_daily_stats(data['daily_stats'], result, user_id)
        
        # 同步回向模板（模板是全局的，但记录创建者）
        if 'dedication_templates' in data:
            sync_logger.info(f"开始同步回向模板，数量: {len(data['dedication_templates'])}")
            sync_dedication_templates(data['dedication_templates'], result)
        
        db.session.commit()
        sync_logger.info(f"=== 用户 {current_user.username} 数据同步完成 ===")
        sync_logger.info(f"同步结果详情: {result['details']}")
        
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
        sync_logger.info(f"处理用户数据，当前用户: {current_user.username}")
        
        for user_data in users_data:
            username = user_data.get('username')
            # 只允许同步当前登录用户的数据
            if not username or username != current_user.username:
                sync_logger.info(f"跳过用户数据: {username}，不是当前用户")
                continue
            
            # 更新当前用户信息
            updated_fields = []
            if user_data.get('nickname') and user_data.get('nickname') != current_user.nickname:
                current_user.nickname = user_data['nickname']
                updated_fields.append('nickname')
            if user_data.get('avatar') and user_data.get('avatar') != current_user.avatar:
                current_user.avatar = user_data['avatar']
                updated_fields.append('avatar')
            if user_data.get('avatar_type') and user_data.get('avatar_type') != current_user.avatar_type:
                current_user.avatar_type = user_data['avatar_type']
                updated_fields.append('avatar_type')
            
            if updated_fields:
                sync_logger.info(f"更新用户 {username} 的字段: {', '.join(updated_fields)}")
                updated_count += 1
            else:
                sync_logger.info(f"用户 {username} 信息无变化，跳过更新")
        
        result['details']['users'] = {
            'updated': updated_count
        }
        sync_logger.info(f"用户数据同步完成: 更新 {updated_count}")
    
    except Exception as e:
        sync_logger.error(f"同步用户数据失败: {str(e)}")

def sync_chantings(chantings_data, result, user_id):
    """同步佛号经文数据"""
    try:
        synced_count = 0
        updated_count = 0
        sync_logger.info(f"处理佛号经文数据，用户ID: {user_id}")
        
        for i, chanting_data in enumerate(chantings_data):
            sync_logger.info(f"处理第 {i+1}/{len(chantings_data)} 个佛号经文: {chanting_data.get('title', 'N/A')}")
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
                sync_logger.info(f"更新现有佛号经文: {title} (ID: {existing.id})")
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
                
                sync_logger.info(f"创建新佛号经文: {title}, 类型: {chanting_type}, 内置: {is_built_in}")
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
            else:
                sync_logger.info(f"跳过佛号经文 {title}，因为已存在且不属于当前用户")
        
        result['details']['chantings'] = {
            'synced': synced_count,
            'updated': updated_count
        }
        sync_logger.info(f"佛号经文同步完成: 新建 {synced_count}, 更新 {updated_count}")
    
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
        sync_logger.info(f"处理修行记录数据，用户ID: {user_id}")
        
        for i, record_data in enumerate(records_data):
            sync_logger.info(f"处理第 {i+1}/{len(records_data)} 个修行记录")
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
                sync_logger.warning(f"找不到对应的佛号经文: {chanting_title}")
                continue
            
            sync_logger.info(f"找到佛号经文: {chanting_title} (ID: {chanting.id})")
            
            # 检查用户的记录是否已存在
            existing = ChantingRecord.query.filter_by(
                chanting_id=chanting.id,
                user_id=user_id
            ).first()
            if existing:
                sync_logger.info(f"修行记录已存在，跳过: {chanting_title}")
                continue
            
            sync_logger.info(f"创建新的修行记录: {chanting_title}")
            new_record = ChantingRecord(
                chanting_id=chanting.id,
                user_id=user_id,
                created_at=parse_datetime(record_data.get('created_at')),
                updated_at=parse_datetime(record_data.get('updated_at'))
            )
            db.session.add(new_record)
            synced_count += 1
        
        result['details']['chanting_records'] = {'synced': synced_count}
        sync_logger.info(f"修行记录同步完成: 新建 {synced_count}")
    
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