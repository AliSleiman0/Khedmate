import apiClient from './client'

export interface ReminderRule {
  id: string
  category: string
  intervalDays: number
  isActive: boolean
  createdAt: string
  updatedAt: string | null
}

export async function fetchReminderRules(): Promise<ReminderRule[]> {
  const response = await apiClient.get<{ success: boolean; data: ReminderRule[] }>(
    '/admin/reminder-rules'
  )
  return response.data.data
}

export async function updateReminderRule(
  id: string,
  intervalDays: number,
  isActive: boolean
): Promise<ReminderRule> {
  const response = await apiClient.put<{ success: boolean; data: ReminderRule }>(
    `/admin/reminder-rules/${id}`,
    { intervalDays, isActive }
  )
  return response.data.data
}

export async function createReminderRule(
  category: string,
  intervalDays: number
): Promise<ReminderRule> {
  const response = await apiClient.post<{ success: boolean; data: ReminderRule }>(
    '/admin/reminder-rules',
    { category, intervalDays }
  )
  return response.data.data
}
