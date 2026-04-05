import apiClient from './client'

export type DisputeStatus = 'Open' | 'Resolved' | 'Rejected'

export interface AdminDisputeSummary {
  disputeId: string
  jobId: string
  referenceNumber: string
  customerId: string
  customerName: string
  providerId: string
  providerName: string
  amount: number
  status: DisputeStatus
  createdAt: string
}

export interface AdminDisputeStatusHistory {
  previousStatus: string
  newStatus: string
  changedAt: string
  changedBy: string
}

export interface AdminDisputeDetail extends AdminDisputeSummary {
  categoryId: string
  address: string
  complaint: string
  adminNote: string | null
  resolvedAt: string | null
  resolvedByAdminId: string | null
  jobCreatedAt: string
  jobCompletedAt: string | null
  photos: string[]
  statusHistory: AdminDisputeStatusHistory[]
}

export interface AdminDisputesResponse {
  items: AdminDisputeSummary[]
  totalCount: number
  page: number
  pageSize: number
  openCount: number
  resolvedCount: number
  rejectedCount: number
}

export interface DisputesFilters {
  status?: string
  search?: string
  page: number
  pageSize: number
}

export async function fetchAdminDisputes(
  filters: DisputesFilters
): Promise<AdminDisputesResponse> {
  const params: Record<string, string | number> = {
    page: filters.page,
    pageSize: filters.pageSize,
  }
  if (filters.status) params.status = filters.status
  if (filters.search) params.search = filters.search

  const response = await apiClient.get('/admin/disputes', { params })
  return response.data.data as AdminDisputesResponse
}

export async function fetchAdminDisputeDetail(
  disputeId: string
): Promise<AdminDisputeDetail> {
  const response = await apiClient.get(`/admin/disputes/${disputeId}`)
  return response.data.data as AdminDisputeDetail
}

export async function resolveDispute(
  disputeId: string,
  action: 'approve_refund' | 'reject',
  adminNote: string
): Promise<void> {
  await apiClient.post(`/admin/disputes/${disputeId}/resolve`, {
    action,
    adminNote,
  })
}
