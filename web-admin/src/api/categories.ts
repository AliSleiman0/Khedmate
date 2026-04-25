import apiClient from './client'

export interface Category {
  id: string
  slug: string
  nameEn: string
  nameAr: string
  iconKey: string
  iconUrl: string | null
  displayOrder: number
  isActive: boolean
  requiresSkillTest: boolean
  publishedQuestionCount: number
  createdAt: string
  updatedAt: string
}

export interface CreateCategoryInput {
  slug: string
  nameEn: string
  nameAr: string
  iconKey: string
  displayOrder: number
  requiresSkillTest: boolean
}

export interface UpdateCategoryInput {
  nameEn?: string
  nameAr?: string
  iconKey?: string
  displayOrder?: number
  requiresSkillTest?: boolean
}

type Envelope<T> = { success: boolean; data: T }

export async function fetchCategories(): Promise<Category[]> {
  const response = await apiClient.get<Envelope<Category[]>>('/admin/categories')
  return response.data.data
}

export async function createCategory(input: CreateCategoryInput): Promise<Category> {
  const response = await apiClient.post<Envelope<Category>>('/admin/categories', input)
  return response.data.data
}

export async function updateCategory(
  id: string,
  input: UpdateCategoryInput,
): Promise<Category> {
  const response = await apiClient.put<Envelope<Category>>(`/admin/categories/${id}`, input)
  return response.data.data
}

export async function setCategoryActive(
  id: string,
  isActive: boolean,
): Promise<Category> {
  const response = await apiClient.patch<Envelope<Category>>(
    `/admin/categories/${id}/active`,
    { isActive },
  )
  return response.data.data
}

export async function deleteCategory(id: string): Promise<void> {
  await apiClient.delete(`/admin/categories/${id}`)
}
