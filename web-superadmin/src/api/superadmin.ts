import client from './client'

export interface DashboardData {
  totalCustomers: number
  totalProviders: number
  platformRevenueMtd: number
  activeJobs: number
}

export interface AdminRow {
  id: string
  email: string
  role: 'admin' | 'superadmin'
  isActive: boolean
  createdAt: string
}

export interface AdminsPage {
  admins: AdminRow[]
  total: number
  page: number
  pageSize: number
}

export interface PlatformConfigData {
  commissionRate: number
  jobTimeoutMinutes: number
  maxProvidersPerArea: number
  minRatingToRemain: number
  autoRefundThresholdDays: number
  updatedAt: string
}

export interface FinancialTransaction {
  id: string
  referenceNumber: string
  customerName: string
  providerName: string
  grossAmount: number
  commissionAmount: number
  netPayout: number
  status: string
  createdAt: string
}

export interface FinancialsPage {
  summary: {
    totalSettled: number
    totalPending: number
    totalRefunded: number
  }
  transactions: FinancialTransaction[]
  total: number
  page: number
  pageSize: number
}

export interface AuditEntry {
  id: string
  adminEmail: string
  actionType: string
  description: string
  targetType: string | null
  targetId: string | null
  createdAt: string
}

export interface AuditPage {
  entries: AuditEntry[]
  total: number
  page: number
  pageSize: number
}

export const superAdminApi = {
  getDashboard: (): Promise<DashboardData> =>
    client.get('/superadmin/dashboard').then((r: { data: { data: DashboardData } }) => r.data.data),

  getAdmins: (page: number): Promise<AdminsPage> =>
    client.get('/superadmin/admins', { params: { page, pageSize: 20 } }).then((r: { data: { data: AdminsPage } }) => r.data.data),

  createAdmin: (body: { email: string; password: string; role: string }) =>
    client.post('/superadmin/admins', body).then((r: { data: { data: AdminRow } }) => r.data.data),

  updateAdmin: (id: string, body: { role: string; isActive: boolean }) =>
    client.put(`/superadmin/admins/${id}`, body).then((r: { data: { data: AdminRow } }) => r.data.data),

  revokeAdmin: (id: string) =>
    client.delete(`/superadmin/admins/${id}`).then((r: { data: { success: boolean } }) => r.data),

  getConfig: (): Promise<PlatformConfigData> =>
    client.get('/superadmin/config').then((r: { data: { data: PlatformConfigData } }) => r.data.data),

  saveConfig: (body: Omit<PlatformConfigData, 'updatedAt'>): Promise<PlatformConfigData> =>
    client.put('/superadmin/config', body).then((r: { data: { data: PlatformConfigData } }) => r.data.data),

  getFinancials: (params: { from: string; to: string; page: number }): Promise<FinancialsPage> =>
    client.get('/superadmin/financials', { params: { ...params, pageSize: 20 } }).then((r: { data: { data: FinancialsPage } }) => r.data.data),

  getAudit: (params: { from: string; to: string; page: number; actionType?: string }): Promise<AuditPage> =>
    client.get('/superadmin/audit', { params: { ...params, pageSize: 20 } }).then((r: { data: { data: AuditPage } }) => r.data.data),
}
