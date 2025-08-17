from datetime import datetime
from database import db

class ChantingRecord(db.Model):
    """修行记录模型 - 对应Flutter应用的ChantingRecord"""
    __tablename__ = 'chanting_records'
    
    id = db.Column(db.Integer, primary_key=True)
    chanting_id = db.Column(db.Integer, db.ForeignKey('chantings.id'), nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True)  # 可选，如果需要用户关联
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def to_dict(self):
        """转换为字典格式"""
        return {
            'id': self.id,
            'chanting_id': self.chanting_id,
            'user_id': self.user_id,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }
    
    def to_dict_with_chanting(self):
        """包含佛号经文详情的字典格式"""
        data = self.to_dict()
        if self.chanting:
            data['chanting'] = self.chanting.to_dict()
        return data
    
    def to_dict_with_user_and_chanting(self):
        """包含用户和佛号经文详情的字典格式"""
        data = self.to_dict()
        if hasattr(self, 'chanting') and self.chanting:
            data['chanting'] = self.chanting.to_dict()
        if hasattr(self, 'user') and self.user:
            data['user'] = {
                'id': self.user.id,
                'username': self.user.username,
                'nickname': self.user.nickname,
                'avatar': self.user.avatar,
                'avatar_type': self.user.avatar_type
            }
        return data