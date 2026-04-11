import apiClient from './client'

export interface AdminDashboardRecentJob {
  jobId: string
  referenceNumber: string
  customerName: string
  status: string
  createdAt: string
}

export interface AdminDashboardData {
  totalJobs: number
  pendingJobs: number
  activeJobs: number
  openDisputes: number
  pendingVerifications: number
  todayRevenue: number
  recentJobs: AdminDashboardRecentJob[]
}

export async function fetchAdminDashboard(): Promise<AdminDashboardData> {
  const response = await apiClient.get<{ success: boolean; data: AdminDashboardData }>(
    '/admin/dashboard'
  )
  return response.data.data
}
