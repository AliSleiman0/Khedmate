import apiClient from './client'

export interface AdminCustomerSummary {
  id: string
  fullName: string
  phone: string
  email: string | null
  totalBookings: number
  isActive: boolean
  createdAt: string
  referralCode: string | null
}

export interface AdminCustomersResponse {
  customers: AdminCustomerSummary[]
  total: number
  page: number
  pageSize: number
}

export interface AdminCustomersFilters {
  search?: string
  isActive?: boolean
  page: number
  pageSize: number
}

export async function fetchAdminCustomers(filters: AdminCustomersFilters): Promise<AdminCustomersResponse> {
  const params = new URLSearchParams()
  if (filters.search) params.set('search', filters.search)
  if (filters.isActive !== undefined) params.set('isActive', String(filters.isActive))
  params.set('page', String(filters.page))
  params.set('pageSize', String(filters.pageSize))

  const response = await apiClient.get<{ success: boolean; data: AdminCustomersResponse }>(
    `/customers?${params.toString()}`
  )
  return response.data.data
}

export async function deactivateCustomer(id: string): Promise<void> {
  await apiClient.patch(`/customers/${id}/deactivate`)
}
