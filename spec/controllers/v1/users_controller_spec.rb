require 'rails_helper'

RSpec.describe V1::UsersController, type: :controller do
  describe 'POST #check_status' do
    let(:valid_attributes) do
      {
        idfa: '8264148c-be95-4b2b-b260-6ee98dd53bf6',
        rooted_device: false
      }
    end

    context 'when user does not exist' do
      it 'creates a new user and returns ban status' do
        expect {
          post :check_status, params: valid_attributes, as: :json
        }.to change(User, :count).by(1)

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to include('ban_status')
      end
    end

    context 'when user exists and is not banned' do
      let!(:user) { create(:user, idfa: valid_attributes[:idfa], ban_status: :not_banned) }

      it 'returns the ban status without creating a new user' do
        expect {
          post :check_status, params: valid_attributes, as: :json
        }.not_to change(User, :count)

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to include('ban_status')
      end
    end

    context 'when user exists and is banned' do
      let!(:user) { create(:user, idfa: valid_attributes[:idfa], ban_status: :banned) }

      it 'returns banned status without running security checks' do
        expect {
          post :check_status, params: valid_attributes, as: :json
        }.not_to change(User, :count)

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq({ 'ban_status' => 'banned' })
      end
    end

    context 'when idfa parameter is missing' do
      it 'returns a bad request error' do
        post :check_status, params: { rooted_device: false }, as: :json

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)).to include('errors')
      end
    end

    describe 'CF-IPCountry security checks' do
      before do
        # Setup country whitelist for tests
        CountryWhitelistService.clear_whitelist
        CountryWhitelistService.add_countries('US', 'CA', 'GB')
      end

      after do
        CountryWhitelistService.clear_whitelist
      end

      context 'when CF-IPCountry header contains whitelisted country' do
        it 'allows the request and returns not_banned status' do
          request.headers['CF-IPCountry'] = 'US'
          
          post :check_status, params: valid_attributes, as: :json
          
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)['ban_status']).to eq('not_banned')
        end
      end

      context 'when CF-IPCountry header contains non-whitelisted country' do
        it 'bans the user and returns banned status' do
          request.headers['CF-IPCountry'] = 'CN'
          
          post :check_status, params: valid_attributes, as: :json
          
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)['ban_status']).to eq('banned')
          
          # Verify user was actually banned in database
          user = User.find_by(idfa: valid_attributes[:idfa])
          expect(user.ban_status).to eq('banned')
        end
      end

      context 'when CF-IPCountry header is missing' do
        it 'allows the request (no header means direct access or a failed Cloudflare check)' do
          post :check_status, params: valid_attributes, as: :json
          
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)['ban_status']).to eq('not_banned')
        end
      end
    end

    describe 'Rooted Device security checks' do
      context 'when rooted_device is false' do
        it 'allows the request and returns not_banned status' do
          params_with_rooted_false = valid_attributes.merge(rooted_device: false)
          
          post :check_status, params: params_with_rooted_false, as: :json
          
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)['ban_status']).to eq('not_banned')
        end
      end

      context 'when rooted_device is true' do
        it 'bans the user and returns banned status' do
          params_with_rooted_true = valid_attributes.merge(rooted_device: true)
          
          post :check_status, params: params_with_rooted_true, as: :json
          
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)['ban_status']).to eq('banned')
          
          # Verify user was actually banned in database
          user = User.find_by(idfa: valid_attributes[:idfa])
          expect(user.ban_status).to eq('banned')
        end
      end

      context 'when rooted_device parameter is missing' do
        it 'allows the request (defaults to not rooted)' do
          post :check_status, params: { idfa: valid_attributes[:idfa] }, as: :json
          
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)['ban_status']).to eq('not_banned')
        end
      end

      context 'when rooted_device is a string' do
        it 'returns a bad request error when rooted_device is "true" (only booleans accepted)' do
          params_with_string_true = valid_attributes.merge(rooted_device: 'true')
          
          post :check_status, params: params_with_string_true, as: :json
          
          expect(response).to have_http_status(:bad_request)
          expect(JSON.parse(response.body)['errors']).to include(V1::UsersController::InvalidRootedDeviceError::MESSAGE)
        end

        it 'returns a bad request error when rooted_device is "false" (only booleans accepted)' do
          params_with_string_false = valid_attributes.merge(rooted_device: 'false')
          
          post :check_status, params: params_with_string_false, as: :json
          
          expect(response).to have_http_status(:bad_request)
          expect(JSON.parse(response.body)['errors']).to include(V1::UsersController::InvalidRootedDeviceError::MESSAGE)
        end

        it 'returns a bad request error when rooted_device is an invalid string (only booleans accepted)' do
          params_with_invalid_string = valid_attributes.merge(rooted_device: 'invalid')
          
          post :check_status, params: params_with_invalid_string, as: :json
          
          expect(response).to have_http_status(:bad_request)
          expect(JSON.parse(response.body)['errors']).to include(V1::UsersController::InvalidRootedDeviceError::MESSAGE)
        end
      end
    end

    describe 'Combined security checks' do
      before do
        CountryWhitelistService.clear_whitelist
        CountryWhitelistService.add_countries('US', 'CA', 'GB')
      end

      after do
        CountryWhitelistService.clear_whitelist
      end

      context 'when both country and rooted device checks fail' do
        it 'bans the user' do
          request.headers['CF-IPCountry'] = 'CN'
          params_with_rooted_true = valid_attributes.merge(rooted_device: true)
          
          post :check_status, params: params_with_rooted_true, as: :json
          
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)['ban_status']).to eq('banned')
        end
      end

      context 'when only rooted device check fails' do
        it 'bans the user' do
          request.headers['CF-IPCountry'] = 'US'
          params_with_rooted_true = valid_attributes.merge(rooted_device: true)
          
          post :check_status, params: params_with_rooted_true, as: :json
          
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)['ban_status']).to eq('banned')
        end
      end

      context 'when only country check fails' do
        it 'bans the user' do
          request.headers['CF-IPCountry'] = 'CN'
          params_with_rooted_false = valid_attributes.merge(rooted_device: false)
          
          post :check_status, params: params_with_rooted_false, as: :json
          
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)['ban_status']).to eq('banned')
        end
      end

      context 'when both checks pass' do
        it 'allows the request' do
          request.headers['CF-IPCountry'] = 'US'
          params_with_rooted_false = valid_attributes.merge(rooted_device: false)
          
          post :check_status, params: params_with_rooted_false, as: :json
          
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)['ban_status']).to eq('not_banned')
        end
      end
    end
  end
end
