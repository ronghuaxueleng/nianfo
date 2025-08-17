from flask import Blueprint, render_template, jsonify
from flask_login import login_required
from sqlalchemy import func
from models.user import User
from models.chanting import Chanting
from models.dedication import Dedication
from models.chanting_record import ChantingRecord
from models.daily_stats import DailyStats

main_bp = Blueprint('main', __name__)

@main_bp.route('/')
def index():
    """首页"""
    return render_template('index.html')

@main_bp.route('/dashboard')
@login_required
def dashboard():
    """管理后台首页"""
    # 统计数据
    stats = {
        'total_users': User.query.count(),
        'total_chantings': Chanting.query.filter_by(is_deleted=False).count(),
        'total_records': ChantingRecord.query.count(),
        'total_dedications': Dedication.query.count(),
        'built_in_chantings': Chanting.query.filter_by(is_built_in=True, is_deleted=False).count(),
        'custom_chantings': Chanting.query.filter_by(is_built_in=False, is_deleted=False).count()
    }
    
    # 最近的用户
    recent_users = User.query.order_by(User.created_at.desc()).limit(5).all()
    
    # 最近的修行记录
    recent_records = ChantingRecord.query.order_by(ChantingRecord.created_at.desc()).limit(10).all()
    
    return render_template('dashboard.html', 
                         stats=stats, 
                         recent_users=recent_users,
                         recent_records=recent_records)