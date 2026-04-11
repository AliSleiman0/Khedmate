import apiClient from './client'

export interface PlatformConfigData {
  commissionRate: number
  jobTimeoutMinutes: number
  maxProvidersPerArea: number
  minRatingToRemain: number
  autoRefundThresholdDays: number
  updatedAt: string
}

export async function fetchPlatformConfig(): Promise<PlatformConfigData> {
  const response = await apiClient.get<{ success: boolean; data: PlatformConfigData }>(
    '/admin/platform-config'
  )
  return response.data.data
}
