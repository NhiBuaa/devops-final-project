import axios from 'axios';
import type { Member } from './types';

const API_URL = import.meta.env.VITE_API_URL || '/api';

export const api = axios.create({
    baseURL: API_URL,
});

export const getMembers = () => api.get<Member[]>('/members');
export const createMember = (member: Omit<Member, 'id'>) => api.post<Member>('/members', member);
export const updateMember = (id: number, member: Omit<Member, 'id'>) => api.put<Member>(`/members/${id}`, member);
export const deleteMember = (id: number) => api.delete(`/members/${id}`);