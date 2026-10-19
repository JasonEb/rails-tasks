require "rails_helper"

RSpec.describe ApplicationCable::Connection, type: :channel do
  let(:user) { create(:user) }

  it "identifies the user from the token query param" do
    connect "/cable", params: { token: user.auth_token }

    expect(connection.current_user).to eq(user)
  end

  it "rejects a connection without a token" do
    expect { connect "/cable" }.to have_rejected_connection
  end

  it "rejects a connection with an unknown token" do
    expect { connect "/cable", params: { token: "nope" } }.to have_rejected_connection
  end
end
