import apiClient from './client'

export interface AdminSubscriptionItem {
  subscriptionId: string
  providerId: string
  providerName: string
  providerPhone: string
  planId: string
  planName: string
  status: 'Active' | 'PastDue' | 'Cancelled' | 'Paused'
  monthlyFee: number
  commissionRate: number
  currentPeriodStart: string
  currentPeriodEnd: string
  stripeSubscriptionId: string | null
  createdAt: string
}

export interface AdminSubscriptionsResponse {
  items: AdminSubscriptionItem[]
  total: number
  page: number
  pageSize: number
  activeCount: number
  pastDueCount: number
}

export interface AdminSubscriptionsFilters {
  search?: string
  status?: string
  page: number
  pageSize: number
}

export async function fetchAdminSubscriptions(
  filters: AdminSubscriptionsFilters
): Promise<AdminSubscriptionsResponse> {
  const params = new URLSearchParams()
  if (filters.search) params.set('search', filters.search)
  if (filters.status) params.set('status', filters.status)
  params.set('page', String(filters.page))
  params.set('pageSize', String(filters.pageSize))

  const response = await apiClient.get<{ success: boolean; data: AdminSubscriptionsResponse }>(
    `/admin/subscriptions?${params.toString()}`
  )
  return response.data.data
}
