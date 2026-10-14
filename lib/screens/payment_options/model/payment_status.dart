/// Top-level `payment_status` on the order (from POST /orders and
/// GET /orders/{slug}). For checkout only three matter: pending = keep waiting,
/// completed = success, failed = failed. The rest are post-fulfilment states.
enum OrderPaymentStatus {
  pending,
  authorized,
  partiallyPaid,
  completed,
  partiallyRefunded,
  refunded,
  voided,
  failed,
  unknown;

  static OrderPaymentStatus fromString(String? value) {
    switch (value) {
      case 'pending':
        return OrderPaymentStatus.pending;
      case 'authorized':
        return OrderPaymentStatus.authorized;
      case 'partially_paid':
        return OrderPaymentStatus.partiallyPaid;
      case 'completed':
        return OrderPaymentStatus.completed;
      case 'partially_refunded':
        return OrderPaymentStatus.partiallyRefunded;
      case 'refunded':
        return OrderPaymentStatus.refunded;
      case 'voided':
        return OrderPaymentStatus.voided;
      case 'failed':
        return OrderPaymentStatus.failed;
      default:
        return OrderPaymentStatus.unknown;
    }
  }

  bool get isCompleted => this == OrderPaymentStatus.completed;
  bool get isFailed => this == OrderPaymentStatus.failed;
  bool get isPending => this == OrderPaymentStatus.pending;
}

/// Top-level order `status`. `cancelled` = order killed (cancel/retry-limit/expiry).
enum OrderTopStatus {
  open,
  archived,
  cancelled,
  unknown;

  static OrderTopStatus fromString(String? value) {
    switch (value) {
      case 'open':
        return OrderTopStatus.open;
      case 'archived':
        return OrderTopStatus.archived;
      case 'cancelled':
        return OrderTopStatus.cancelled;
      default:
        return OrderTopStatus.unknown;
    }
  }

  bool get isCancelled => this == OrderTopStatus.cancelled;
}
