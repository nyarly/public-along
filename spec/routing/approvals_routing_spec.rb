require 'rails_helper'

RSpec.describe ApprovalsController, type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: '/approvals').to route_to('approvals#index')
    end

    it 'routes to #show' do
      expect(get: '/approvals/1').to route_to('approvals#show', id: '1')
    end

    it 'routes to #edit' do
      expect(get: '/approvals/1/edit').to route_to('approvals#edit', id: '1')
    end

    it 'routes to #update via PUT' do
      expect(put: '/approvals/1').to route_to('approvals#update', id: '1')
    end

    it 'routes to #update via PATCH' do
      expect(patch: '/approvals/1').to route_to('approvals#update', id: '1')
    end
  end
end
