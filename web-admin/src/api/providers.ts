import apiClient from './client'

export interface AdminProviderSummary {
  id: string
  fullName: string
  phone: string
  email: string | null
  tier: string
  serviceCategories: string[]
  rating: number
  jobsCompleted: number
  createdAt: string
}

export interface AdminProvidersResponse {
  providers: AdminProviderSummary[]
  total: number
  page: number
  pageSize: number
}

export interface AdminProvidersFilters {
  tier?: string
  categoryId?: string
  page: number
  pageSize: number
}

export interface VerificationQueueItem {
  providerId: string
  fullName: string
  phone: string
  documentType: string
  submittedAt: string
  submissionId: string
}

export async function fetchAdminProviders(filters: AdminProvidersFilters): Promise<AdminProvidersResponse> {
  const params = new URLSearchParams()
  if (filters.tier) params.set('tier', filters.tier)
  if (filters.categoryId) params.set('categoryId', filters.categoryId)
  params.set('page', String(filters.page))
  params.set('pageSize', String(filters.pageSize))

  const response = await apiClient.get<{ success: boolean; data: AdminProvidersResponse }>(
    `/admin/providers?${params.toString()}`
  )
  return response.data.data
}

export async function fetchVerificationQueue(page = 1, pageSize = 20): Promise<VerificationQueueItem[]> {
  const response = await apiClient.get<{ success: boolean; data: VerificationQueueItem[] }>(
    `/admin/providers/verification-queue?page=${page}&pageSize=${pageSize}`
  )
  return response.data.data
}

export async function verifyDocuments(
  providerId: string,
  submissionId: string,
  action: 'approve' | 'reject',
  rejectionReason?: string
): Promise<void> {
  await apiClient.post(`/admin/providers/${providerId}/verify-documents`, {
    submissionId,
    action,
    rejectionReason,
  })
}
