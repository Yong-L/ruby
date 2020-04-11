require 'rails_helper'

RSpec.describe 'Webhooks API', type: :request do
  before { freeze_time }
  let(:current_time) { Time.current.utc.iso8601(3).to_s }

  # Test suite for POST /webhooks
  describe 'POST /webhooks' do
    let(:customer) { { 'id': 'justin_mckibben' } }
    let(:seller_id) { Seller.last['seller_id'] }
    let(:session) do
      {
        'customer': customer,
        'customer_email': nil,
        'display_items': [
          {
            'amount': 5000,
            'currency': 'usd',
            'custom': {
              'description': '$50.00 donation to Shunfa Bakery',
              'images': nil,
              'name': item_name
            },
            'quantity': 1,
            'type': 'custom'
          }
        ],
        'metadata': {
          'merchant_id': seller_id
        },
      }
    end

    let(:payload) do
      {
        'type': 'checkout.session.completed',
        'data': {
          'object': session
        }
      }
    end

    before do
      create :seller
      allow(Stripe::Webhook).to receive(:construct_event)
        .and_return(payload.with_indifferent_access)
      post '/webhooks'
    end

    context 'with donation' do
      let(:item_name) { 'Donation' }

      it 'creates a Donation' do
        donation_detail = DonationDetail.last
        expect(donation_detail).not_to be_nil
        expect(donation_detail['amount']).to eq(5000)
        item = Item.find(donation_detail['item_id'])
        expect(item).not_to be_nil
        expect(item['stripe_customer_id']).to eq('justin_mckibben')
        expect(item.donation?).to be true
        seller = Seller.find_by(seller_id: seller_id)
        expect(item.seller).to eq(seller)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'with gift card' do
      let(:item_name) { 'Gift Card' }

      it 'creates a gift card' do
        gift_card_detail = GiftCardDetail.last
        expect(gift_card_detail).not_to be_nil
        gift_card_amount = GiftCardAmount.find_by(
          gift_card_detail_id: gift_card_detail['id'])
        expect(gift_card_amount['value']).to eq(5000)
        item = Item.find(gift_card_detail['item_id'])
        expect(item).not_to be_nil
        expect(item['stripe_customer_id']).to eq('justin_mckibben')
        expect(item.gift_card?).to be true
        seller = Seller.find_by(seller_id: seller_id)
        expect(item.seller).to eq(seller)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end
  end
end
