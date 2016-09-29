require 'spec_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator.  If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails.  There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.
#
# Compared to earlier versions of this generator, there is very limited use of
# stubs and message expectations in this spec.  Stubs are only used when there
# is no simpler way to get a handle on the object needed for the example.
# Message expectations are only used when there is no simpler way to specify
# that an instance is receiving a specific message.

describe OffensesController do

  # This should return the minimal set of attributes required to create a valid
  # Offense. As you add validations to Offense, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) { { "description" => "MyString" } }

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # OffensesController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  describe "GET index" do
    it "assigns all offenses as @offenses" do
      offense = Offense.create! valid_attributes
      get :index, {}, valid_session
      assigns(:offenses).should eq([offense])
    end
  end

  describe "GET show" do
    it "assigns the requested offense as @offense" do
      offense = Offense.create! valid_attributes
      get :show, {:id => offense.to_param}, valid_session
      assigns(:offense).should eq(offense)
    end
  end

  describe "GET new" do
    it "assigns a new offense as @offense" do
      get :new, {}, valid_session
      assigns(:offense).should be_a_new(Offense)
    end
  end

  describe "GET edit" do
    it "assigns the requested offense as @offense" do
      offense = Offense.create! valid_attributes
      get :edit, {:id => offense.to_param}, valid_session
      assigns(:offense).should eq(offense)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new Offense" do
        expect {
          post :create, {:offense => valid_attributes}, valid_session
        }.to change(Offense, :count).by(1)
      end

      it "assigns a newly created offense as @offense" do
        post :create, {:offense => valid_attributes}, valid_session
        assigns(:offense).should be_a(Offense)
        assigns(:offense).should be_persisted
      end

      it "redirects to the created offense" do
        post :create, {:offense => valid_attributes}, valid_session
        response.should redirect_to(Offense.last)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved offense as @offense" do
        # Trigger the behavior that occurs when invalid params are submitted
        Offense.any_instance.stub(:save).and_return(false)
        post :create, {:offense => { "description" => "invalid value" }}, valid_session
        assigns(:offense).should be_a_new(Offense)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        Offense.any_instance.stub(:save).and_return(false)
        post :create, {:offense => { "description" => "invalid value" }}, valid_session
        response.should render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested offense" do
        offense = Offense.create! valid_attributes
        # Assuming there are no other offenses in the database, this
        # specifies that the Offense created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        Offense.any_instance.should_receive(:update).with({ "description" => "MyString" })
        put :update, {:id => offense.to_param, :offense => { "description" => "MyString" }}, valid_session
      end

      it "assigns the requested offense as @offense" do
        offense = Offense.create! valid_attributes
        put :update, {:id => offense.to_param, :offense => valid_attributes}, valid_session
        assigns(:offense).should eq(offense)
      end

      it "redirects to the offense" do
        offense = Offense.create! valid_attributes
        put :update, {:id => offense.to_param, :offense => valid_attributes}, valid_session
        response.should redirect_to(offense)
      end
    end

    describe "with invalid params" do
      it "assigns the offense as @offense" do
        offense = Offense.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        Offense.any_instance.stub(:save).and_return(false)
        put :update, {:id => offense.to_param, :offense => { "description" => "invalid value" }}, valid_session
        assigns(:offense).should eq(offense)
      end

      it "re-renders the 'edit' template" do
        offense = Offense.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        Offense.any_instance.stub(:save).and_return(false)
        put :update, {:id => offense.to_param, :offense => { "description" => "invalid value" }}, valid_session
        response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested offense" do
      offense = Offense.create! valid_attributes
      expect {
        delete :destroy, {:id => offense.to_param}, valid_session
      }.to change(Offense, :count).by(-1)
    end

    it "redirects to the offenses list" do
      offense = Offense.create! valid_attributes
      delete :destroy, {:id => offense.to_param}, valid_session
      response.should redirect_to(offenses_url)
    end
  end

end