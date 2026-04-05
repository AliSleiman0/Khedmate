import apiClient from './client'

export type JobStatus =
  | 'Pending'
  | 'Accepted'
  | 'EnRoute'
  | 'InProgress'
  | 'Completed'
  | 'Paid'
  | 'Expired'

export interface AdminJobSummary {
  jobId: string
  referenceNumber: string
  customerId: string
  customerName: string
  providerId: string | null
  providerName: string | null
  categoryId: string
  status: JobStatus
  createdAt: string
  acceptedAt: string | null
  paidAt: string | null
  amount: number | null
}

export interface AdminJobStatusHistory {
  previousStatus: string
  newStatus: string
  changedAt: string
  changedBy: string
}

export interface AdminJobRating {
  isPositive: boolean
  tags: string[]
  submittedAt: string
  raterType: string
}

export interface AdminJobDetail {
  jobId: string
  referenceNumber: string
  customerId: string
  customerName: string
  providerId: string | null
  providerName: string | null
  categoryId: string
  description: string
  latitude: number
  longitude: number
  address: string
  status: JobStatus
  createdAt: string
  acceptedAt: string | null
  paidAt: string | null
  amount: number | null
  photoUrls: string[]
  statusHistory: AdminJobStatusHistory[]
  rating: AdminJobRating | null
}

export interface AdminJobStats {
  total: number
  pending: number
  active: number
  completedOrPaid: number
}

export interface AdminJobsFilters {
  search?: string
  status?: string
  from?: string
  to?: string
  page: number
  pageSize: number
}

export interface AdminJobsResponse {
  items: AdminJobSummary[]
  totalCount: number
  page: number
  pageSize: number
  stats: AdminJobStats
}

export async function fetchAdminJobs(filters: AdminJobsFilters): Promise<AdminJobsResponse> {
  const params = new URLSearchParams()
  if (filters.search) params.set('search', filters.search)
  if (filters.status) params.set('status', filters.status)
  if (filters.from) params.set('from', filters.from)
  if (filters.to) params.set('to', filters.to)
  params.set('page', String(filters.page))
  params.set('pageSize', String(filters.pageSize))

  const response = await apiClient.get<{ success: boolean; data: AdminJobsResponse }>(
    `/admin/jobs?${params.toString()}`
  )
  return response.data.data
}

export async function fetchAdminJobDetail(jobId: string): Promise<AdminJobDetail> {
  const response = await apiClient.get<{ success: boolean; data: AdminJobDetail }>(
    `/admin/jobs/${jobId}`
  )
  return response.data.data
}

export async function forceCancel(jobId: string): Promise<void> {
  await apiClient.post(`/admin/jobs/${jobId}/force-cancel`)
}
