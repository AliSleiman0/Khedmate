import React, { useEffect, useState } from 'react';
import apiClient from '../../api/client';

interface Provider {
  id: string;
  fullName: string;
  phone: string;
  email: string | null;
  tier: string;
  serviceCategories: string[];
  rating: number;
  jobsCompleted: number;
  createdAt: string;
}

export const AllProviders: React.FC = () => {
  const [providers, setProviders] = useState<Provider[]>([]);
  const [loading, setLoading] = useState(true);
  const [filters, setFilters] = useState({
    tier: '',
    categoryId: '',
  });

  useEffect(() => {
    loadProviders();
  }, [filters]);

  const loadProviders = async () => {
    try {
      const params = new URLSearchParams();
      if (filters.tier) params.append('tier', filters.tier);
      if (filters.categoryId) params.append('categoryId', filters.categoryId);

      const response = await apiClient.get(`/admin/providers?${params.toString()}`);
      setProviders(response.data.data.providers);
    } catch (error) {
      console.error('Failed to load providers:', error);
    } finally {
      setLoading(false);
    }
  };

  const tierBadgeColor = (tier: string) => {
    switch (tier) {
      case 'Active':
        return 'badge-green';
      case 'SkillTested':
        return 'badge-blue';
      case 'IdVerified':
        return 'badge-yellow';
      default:
        return 'badge-gray';
    }
  };

  if (loading) return <div className="loading">جاري التحميل...</div>;

  return (
    <div className="all-providers">
      <h1>جميع المزودين</h1>

      <div className="filters">
        <select
          value={filters.tier}
          onChange={(e) => setFilters({ ...filters, tier: e.target.value })}
        >
          <option value="">كل المستويات</option>
          <option value="Unverified">غير محقق</option>
          <option value="PhoneVerified">هاتف محقق</option>
          <option value="IdVerified">هوية محققة</option>
          <option value="SkillTested">مهارة محققة</option>
          <option value="Active">نشط</option>
        </select>
      </div>

      <table className="table">
        <thead>
          <tr>
            <th>الاسم</th>
            <th>الهاتف</th>
            <th>المستوى</th>
            <th>الفئات</th>
            <th>التقييم</th>
            <th>الوظائف المكتملة</th>
            <th>تاريخ التسجيل</th>
          </tr>
        </thead>
        <tbody>
          {providers.map((provider) => (
            <tr key={provider.id}>
              <td>{provider.fullName}</td>
              <td>{provider.phone}</td>
              <td>
                <span className={`badge ${tierBadgeColor(provider.tier)}`}>
                  {provider.tier}
                </span>
              </td>
              <td>{provider.serviceCategories.join(', ')}</td>
              <td>{provider.rating.toFixed(1)}</td>
              <td>{provider.jobsCompleted}</td>
              <td>{new Date(provider.createdAt).toLocaleDateString('ar-EG')}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};
