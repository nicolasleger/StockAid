module Users
  module OrderManipulator
    extend ActiveSupport::Concern

    def can_edit_order?(order)
      super_admin? || can_edit_order_at?(order.organization) && !order.order_submitted?
    end

    def can_edit_order_at?(organization)
      super_admin? || member_at?(organization)
    end

    def can_create_order_at?(organization)
      super_admin? || member_at?(organization)
    end

    def create_order(params)
      transaction do
        organization = Organization.find(params[:order][:organization_id])
        raise PermissionError unless can_create_order_at?(organization)
        order = Order.new(organization: organization,
                          user: self,
                          order_date: Time.zone.now,
                          status: :select_ship_to)
        order.ship_to_name = name unless super_admin?
        OrderDetailsUpdater.new(order, params).update
        order.save!
        order
      end
    end

    def update_order(params)
      transaction do
        order = Order.find params[:id]
        OrderUpdater.new(order, params).update
        order.save!
        order
      end
    end

    def ship_to_names(order)
      if super_admin? || order.user.super_admin?
        order.organization_ship_to_names
      else
        order.ship_to_names
      end
    end
  end
end
