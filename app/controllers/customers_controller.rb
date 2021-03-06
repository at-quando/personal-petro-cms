class CustomersController < ApplicationController
  before_action :set_params, only: [:edit, :show, :update, :destroy]

  def new
    @customer = Customer.new
    uri   = URI.parse(request.fullpath)
    if uri.query
      params = CGI.parse(uri.query)
      content   = params['car'].first
      @customer.car_number = content
    end
    @fuels = Fuel.all
    @petro = @customer.day_fuel_petros.build
  end

  def index_all
    # @customers = Customer.all.includes[:petro].page(params[:page]).per(100)
    if params[:start] && params[:end]
      start_date =  DateTime.parse(params[:start])
      end_date = DateTime.parse(params[:end])
      @customers =  Petro.all.where("day_fuel BETWEEN ? AND ?",start_date, end_date).group_by(&:customer)
    else
      @customers = nil
    end
  end 

  def create
    params[:customer][:day_fuel_petros_attributes]["0"][:day_fuel] = DateTime.strptime(params["day_fuel"], '%d/%m/%Y')
    fuel = Fuel.find(JSON.parse(params["type_of_fuel"])[0])
    params[:customer][:day_fuel_petros_attributes]["0"][:price_fuel] = fuel.price
    params[:customer][:day_fuel_petros_attributes]["0"][:type_fuel] = fuel.name
    params[:customer][:type_customer] = Integer(customer_params[:type_customer])
    params[:customer][:car_number] = params[:customer][:car_number].gsub(/\s+/, "").upcase
    params[:customer][:day_fuel_petros_attributes]["0"][:amount] = Float(params[:customer][:day_fuel_petros_attributes]["0"][:money])/Float(params[:customer][:day_fuel_petros_attributes]["0"][:price_fuel])
    params[:customer][:last_date_petro] = params[:customer][:day_fuel_petros_attributes]["0"][:day_fuel]
    @customer = Customer.new(customer_params)
    if @customer.save 
      flash[:success] = 'Khách hàng đã được tạo.'
      redirect_to @customer
    else
      flash[:alert] = @customer.errors.full_messages.join('  ;  ')
      redirect_to new_customer_path(car: params[:customer][:car_number])
    end
  end

  def index
    @customers = Customer.all.includes(:petros).order(last_date_petro: :desc).page(params[:page])
  end

  def show
    @petro = Petro.new
    @petros = Petro.where(customer_id: params[:id]).order(day_fuel: :desc)
    @fuels = Fuel.all
  end
  
  def edit
  end

  def update
    params[:customer][:type_customer] = Integer(customer_params[:type_customer])
    if @customer.update(customer_params)
      flash[:success] = 'Khách hàng đã được cập nhật!'
      redirect_to @customer
    else
      render :edit
    end
  end

  def destroy
    @customer.destroy
    flash[:error] = 'Khách hàng đã được xóa.'
    redirect_to customers_path
  end

  def search_customer
    @customer = Customer.new
  end

  def search
    search_num = (params[:car_location] + '-' + params[:car_num]).gsub(/\s+/, "").upcase
    @customer = Customer.find_by(car_number: search_num)
    if @customer
      flash[:alert] = 'Khách hàng đã tồn tại. Đến trang thông tin khách hàng.'
      redirect_to @customer
    else
      redirect_to new_customer_path(car: search_num), notice: 'Biến số xe không tồn tại, vui lòng tạo khách hàng mới.' 
    end

  end

  def set_init_date
    Customer.all.page(params[:page]).per(params[:limit]).each do |customer|
      if customer.petros.length > 0
        customer.update(last_date_petro: customer.petros[0].day_fuel)
      end
    end
  end

  private
  def set_params
    @customer = Customer.find(params[:id])
  end

  def customer_params
  	params.require(:customer).permit(:name,:phone, :car_number, :company, :type_customer, day_fuel_petros_attributes: [:money, :amount, :type_fuel, :day_fuel, :price_fuel]) 
  end
end
