from flask import Blueprint, render_template, redirect, url_for, flash, request
from flask_login import login_user, logout_user, login_required, current_user
from datetime import datetime
from database import db
from models.user import AdminUser

auth_bp = Blueprint('auth', __name__)

@auth_bp.route('/login', methods=['GET', 'POST'])
def login():
    """管理员登录"""
    if current_user.is_authenticated:
        return redirect(url_for('main.dashboard'))
    
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        
        if not username or not password:
            flash('请输入用户名和密码', 'error')
            return render_template('auth/login.html')
        
        admin = AdminUser.query.filter_by(username=username).first()
        
        if admin and admin.check_password(password):
            login_user(admin)
            admin.last_login = datetime.utcnow()
            db.session.commit()
            
            next_page = request.args.get('next')
            if next_page:
                return redirect(next_page)
            
            flash(f'欢迎回来，{admin.username}！', 'success')
            return redirect(url_for('main.dashboard'))
        else:
            flash('用户名或密码错误', 'error')
    
    return render_template('auth/login.html')

@auth_bp.route('/logout')
@login_required
def logout():
    """管理员登出"""
    logout_user()
    flash('已成功退出', 'info')
    return redirect(url_for('auth.login'))