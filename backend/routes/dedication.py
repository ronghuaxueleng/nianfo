from flask import Blueprint, render_template, request, jsonify, flash, redirect, url_for
from flask_login import login_required
from database import db
from models.dedication import Dedication
from models.chanting import Chanting
from sqlalchemy import or_

dedication_bp = Blueprint('dedication', __name__)

@dedication_bp.route('/')
@login_required
def index():
    """回向文管理页面"""
    # 获取搜索参数
    search = request.args.get('search', '').strip()
    page = request.args.get('page', 1, type=int)
    per_page = 20
    
    # 构建查询
    query = Dedication.query
    
    if search:
        query = query.filter(
            or_(
                Dedication.title.contains(search),
                Dedication.content.contains(search)
            )
        )
    
    # 分页查询
    dedications = query.order_by(Dedication.created_at.desc()).paginate(
        page=page, per_page=per_page, error_out=False
    )
    
    # 获取可用的佛号经文列表
    available_chantings = Chanting.query.filter_by(is_deleted=False).order_by(Chanting.title).all()
    
    return render_template('dedication/index.html', 
                         dedications=dedications.items,
                         pagination=dedications,
                         available_chantings=available_chantings,
                         search=search)