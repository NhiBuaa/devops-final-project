import React, { useEffect, useState } from 'react';
import { Plus, Trash2, Edit2, Users } from 'lucide-react';
import type { Member } from './types';
import * as api from './api';

function App() {
  const [members, setMembers] = useState<Member[]>([]);
  const [name, setName] = useState('');
  const [role, setRole] = useState('');
  const [editingId, setEditingId] = useState<number | null>(null);
  const [error, setError] = useState('');

  const fetchMembers = async () => {
    try {
      const res = await api.getMembers();
      return {
        members: Array.isArray(res.data) ? res.data : [],
        error: Array.isArray(res.data)
          ? ''
          : 'API tra ve du lieu khong dung dinh dang danh sach thanh vien.',
      };
    } catch (err) {
      console.error('Failed to fetch members:', err);
      return {
        members: [],
        error: 'Khong the tai du lieu tu staging. Vui long kiem tra backend va database.',
      };
    }
  };

  useEffect(() => {
    let cancelled = false;

    void fetchMembers().then(({ members, error }) => {
      if (cancelled) {
        return;
      }

      setMembers(members);
      setError(error);
    });

    return () => {
      cancelled = true;
    };
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (editingId) {
      await api.updateMember(editingId, { name, role });
    } else {
      await api.createMember({ name, role });
    }
    setName(''); setRole(''); setEditingId(null);
    const { members, error } = await fetchMembers();
    setMembers(members);
    setError(error);
  };

  const handleEdit = (m: Member) => {
    setEditingId(m.id); setName(m.name); setRole(m.role);
  };

  const handleDelete = async (id: number) => {
    if (confirm('Xóa thành viên này?')) {
      await api.deleteMember(id);
      const { members, error } = await fetchMembers();
      setMembers(members);
      setError(error);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50 to-indigo-100 p-8">
      <div className="max-w-4xl mx-auto">
        <header className="flex items-center justify-between mb-10 bg-white/80 backdrop-blur-xl border border-white/30 rounded-2xl px-8 py-6 shadow-xl">
          <div className="p-3 bg-blue-100 rounded-2xl">
            <Users className="w-8 h-8 text-blue-600" />
          </div>
          <div>
            <h1 className="text-3xl font-bold text-slate-800 tracking-tight">
              Team Management v2.0s
            </h1>
            <p className="text-slate-500 mt-1">
              Manage your development team efficiently
            </p>
          </div>
        </header>

        {error && (
          <div className="mb-6 rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-amber-800">
            {error}
          </div>
        )}

        {/* Form */}
        <form onSubmit={handleSubmit} className="bg-white p-6 rounded-lg shadow-md mb-8 flex gap-4">
          <input value={name} onChange={e => setName(e.target.value)} placeholder="Tên" className="flex-1 border p-2 rounded" required />
          <input value={role} onChange={e => setRole(e.target.value)} placeholder="Vai trò" className="flex-1 border p-2 rounded" required />
          <button type="submit" className="bg-blue-600 text-white px-4 py-2 rounded flex items-center gap-2 hover:bg-blue-700">
            {editingId ? <Edit2 size={18} /> : <Plus size={18} />}
            {editingId ? 'Cập nhật' : 'Thêm'}
          </button>
        </form>

        {/* List */}
        <div className="bg-white rounded-lg shadow-md overflow-hidden">
          <table className="w-full text-left">
            <thead className="bg-gray-50">
              <tr>
                <th className="p-4">Tên</th>
                <th className="p-4">Vai trò</th>
                <th className="p-4 text-right">Thao tác</th>
              </tr>
            </thead>
            <tbody>
              {members.map(m => (
                <tr key={m.id} className="border-t">
                  <td className="p-4 font-medium">{m.name}</td>
                  <td className="p-4 text-gray-600">{m.role}</td>
                  <td className="p-4 text-right flex justify-end gap-2">
                    <button onClick={() => handleEdit(m)} className="p-2 text-blue-600 hover:bg-blue-50 rounded"><Edit2 size={18} /></button>
                    <button onClick={() => handleDelete(m.id)} className="p-2 text-red-600 hover:bg-red-50 rounded"><Trash2 size={18} /></button>
                  </td>
                </tr>
              ))}
              {!members.length && (
                <tr className="border-t">
                  <td className="p-4 text-gray-500" colSpan={3}>
                    Chua co du lieu thanh vien de hien thi.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}

export default App;
