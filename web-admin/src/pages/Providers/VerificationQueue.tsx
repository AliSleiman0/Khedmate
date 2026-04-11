import React, { useEffect, useState } from 'react';
import apiClient from '../../api/client';

interface ProviderVerificationItem {
  providerId: string;
  fullName: string;
  phone: string;
  documentType: string;
  submittedAt: string;
  submissionId: string;
}

export const VerificationQueue: React.FC = () => {
  const [queue, setQueue] = useState<ProviderVerificationItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedSubmission, setSelectedSubmission] = useState<ProviderVerificationItem | null>(null);

  useEffect(() => {
    loadQueue();
  }, []);

  const loadQueue = async () => {
    try {
      const response = await apiClient.get('/admin/providers/verification-queue');
      setQueue(response.data.data);
    } catch (error) {
      console.error('Failed to load queue:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleReview = (item: ProviderVerificationItem) => {
    setSelectedSubmission(item);
  };

  const handleApprove = async (providerId: string, submissionId: string) => {
    try {
      await apiClient.post(`/admin/providers/${providerId}/verify-documents`, {
        submissionId,
        action: 'approve',
      });
      alert('تم قبول الوثائق بنجاح');
      setSelectedSubmission(null);
      loadQueue();
    } catch (error) {
      alert('حدث خطأ أثناء الموافقة');
    }
  };

  const handleReject = async (providerId: string, submissionId: string, reason: string) => {
    if (!reason.trim()) {
      alert('يجب إدخال سبب الرفض');
      return;
    }

    try {
      await apiClient.post(`/admin/providers/${providerId}/verify-documents`, {
        submissionId,
        action: 'reject',
        rejectionReason: reason,
      });
      alert('تم رفض الوثائق');
      setSelectedSubmission(null);
      loadQueue();
    } catch (error) {
      alert('حدث خطأ أثناء الرفض');
    }
  };

  if (loading) return <div className="loading">جاري التحميل...</div>;

  return (
    <div className="verification-queue">
      <h1>قائمة انتظار التحقق من المزودين</h1>
      <table className="table">
        <thead>
          <tr>
            <th>الاسم</th>
            <th>الهاتف</th>
            <th>نوع الوثيقة</th>
            <th>تاريخ الإرسال</th>
            <th>الإجراءات</th>
          </tr>
        </thead>
        <tbody>
          {queue.map((item) => (
            <tr key={item.submissionId}>
              <td>{item.fullName}</td>
              <td>{item.phone}</td>
              <td>{item.documentType}</td>
              <td>{new Date(item.submittedAt).toLocaleDateString('ar-EG')}</td>
              <td>
                <button onClick={() => handleReview(item)}>عرض الوثائق</button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>

      {selectedSubmission && (
        <DocumentReviewModal
          submission={selectedSubmission}
          onApprove={handleApprove}
          onReject={handleReject}
          onClose={() => setSelectedSubmission(null)}
        />
      )}
    </div>
  );
};

interface DocumentReviewModalProps {
  submission: ProviderVerificationItem;
  onApprove: (providerId: string, submissionId: string) => void;
  onReject: (providerId: string, submissionId: string, reason: string) => void;
  onClose: () => void;
}

const DocumentReviewModal: React.FC<DocumentReviewModalProps> = ({
  submission,
  onApprove,
  onReject,
  onClose,
}) => {
  const [rejectionReason, setRejectionReason] = useState('');

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content" onClick={(e) => e.stopPropagation()}>
        <h2>مراجعة وثائق {submission.fullName}</h2>
        <div className="document-images">
          {/* Display images - URLs would come from backend */}
          <p>Front Image: [Image Display Here]</p>
          <p>Back Image: [Image Display Here]</p>
        </div>
        <div className="modal-actions">
          <button
            className="approve-btn"
            onClick={() => onApprove(submission.providerId, submission.submissionId)}
          >
            موافقة
          </button>
          <div className="reject-section">
            <textarea
              placeholder="سبب الرفض"
              value={rejectionReason}
              onChange={(e) => setRejectionReason(e.target.value)}
            />
            <button
              className="reject-btn"
              onClick={() => onReject(submission.providerId, submission.submissionId, rejectionReason)}
            >
              رفض
            </button>
          </div>
          <button onClick={onClose}>إغلاق</button>
        </div>
      </div>
    </div>
  );
};
