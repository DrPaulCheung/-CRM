#encoding=UTF-8
require 'rubygems'
require 'sinatra'
require 'mongo'
require 'digest/md5'  
require 'json/ext' # required for .to_json
require 'json'


#连接数据库
$db = Mongo::Client.new([ '127.0.0.1:27017'], :database => 'DBMS')


use Rack::Session::Pool ,:expire_after => 86400 

configure do  
  enable :sessions  
end  

##########################路由##################

get "/" do
	if session[:admin] == true 
		redirect to('index');
	else
		redirect to('login');
	end
end

#登录
get "/login" do
	if session[:admin] then
		redirect to('index')
	else
		erb :login
	end
end


#获取我的数据
get '/getMyAttribute' do
	result = $db[:db_users].find( "user_name" => session[:username]).to_a.first.to_json;
	return result;

end


post "/login" do
	@username = params[:username]
	@password = params[:password]
	result = $db[:db_users].find( "user_name" => @username).to_a.first.to_json
	puts result
	obj = JSON.parse(result);
	if obj['user_name'] == @username && Digest::MD5.hexdigest(obj['user_password']) ==Digest::MD5.hexdigest( @password )
		session[:admin] = true;
		session[:username] = @username;
		redirect to("index");
	else

	end
	erb :login
end

#主页
get "/index" do
	redirect to('login') unless session[:admin] ;
	@current = "dashboard";
	erb :index,:layout => :content_layout #主页共用模板
end

#登出
get '/logout' do
	session.clear
	redirect to('login')
end



#我的任务便签管理 
post '/addtask' do
	puts params
	task = params[:task];
	data = { "user_todolist"=> {"todo_name"=> task, "todo_state"=> "0" } } ;
	$db[:db_users].update_one({"user_name" => session[:username]} ,{"$addToSet": data  } );
	return 200
end

#移除一条便签
post '/removetask' do
	task = params[:task];
	$db[:db_users].update_one( {'user_name': session[:username] } ,{"$pull": {"user_todolist": {"todo_name": task } } } );
	return 200;
end
#修改一条便签数据
post '/changetask' do
	taskname = params[:taskname];
	taskstate = params[:taskstate];
	$db[:db_users].update_one( {'user_name': session[:username] ,"user_todolist.todo_name": taskname } ,{"$set": {"user_todolist.$.todo_state": taskstate} } );
	return 200;
end
#获取便签数据
get '/gettask' do
	result = $db[:db_users].find( "user_name" => session[:username]).to_a.first.to_json
	resultObj = JSON.parse(result)
	return resultObj['user_todolist'].to_a.to_json;
end




#职员管理
get '/employee' do
	@current = "employee"
	@active = "employee"
	erb :employee, :layout => :content_layout #主页共用模板
end

#获取所有职员信息
post '/getemployee' do
	result = $db[:db_employee].find().to_a.to_json
	return result
end
#创建新的员工信息
post '/addemployee' do
	data = JSON.parse(params[:models]).first;
	insertdata = {"em_name": data['em_name'] ,"em_sex": data['em_sex'], "em_address": data['em_address'],"em_id": data['em_id'],"em_phone": data['em_phone'],"em_email": data['em_email'],"em_job": data['em_job'],"em_state": data['em_state'],"em_jointime": data['em_jointime'] ,"em_age": data['em_age']  };

	$db[:db_employee].insert_one(insertdata);

	result = $db[:db_employee].find({'em_name': data['em_name']}).to_a.to_json
	return result;
end	
#更新一条员工信息
post '/updateemployee' do
	data = JSON.parse(params[:models]).first;

	id = BSON::ObjectId(data['_id']['$oid']);

	insertdata = {"em_name": data['em_name'] ,"em_sex": data['em_sex'], "em_address": data['em_address'],"em_id": data['em_id'],"em_phone": data['em_phone'],"em_email": data['em_email'],"em_job": data['em_job'],"em_state": data['em_state'],"em_jointime": data['em_jointime'],"em_age": data['em_age']   };


	$db[:db_employee].update_one({'_id': id}, {"$set": insertdata});

	return 200
end
#移除员工信息
post '/removeemployee' do
	data = JSON.parse(params[:models]).first;
	id = BSON::ObjectId(data['_id']['$oid']);
	$db[:db_employee].find_one_and_delete({'_id': id});
	return params[:models];
end


#员工招聘管理
get '/recruit' do
	@current = "employee"
	@active = "recruit"
	erb :recruit, :layout => :content_layout #主页共用模板
end

#获取招聘
get '/getrecruit' do
	result = $db[:db_recruit].find().to_a.to_json ;
	return result;
end

#获取招聘列表 
get '/getRecruitList' do
	result = $db[:db_users].find() ;

	returnobj = [];

	result.each do |user|
		returnobj.push( {"invite_name": user[:user_name] +"(" + user[:user_department] + ")" , "user_name": user[:user_name]     });
	end

	puts returnobj;
	return returnobj.to_a.to_json;
end


#新增一条招聘信息
get '/newrecruit' do
	@current = "employee"
	@active = "recruit"
	erb :newrecruit, :layout => :content_layout #主页共用模板
end

#查看招聘信息
get '/viewrecruit' do
	@current = "employee"
	@active = "recruit"
	id = params[:id]
	oid = BSON::ObjectId(id);

	info= $db[:db_recruit].find({"_id": oid}).to_a.first.to_json;
	@recruitInfo = JSON.parse(info);
	puts 'find id......';
	puts @recruitInfo;
	@myname = session[:user_name];
	erb :recruitview, :layout => :content_layout #主页共用模板
end

#新增数据发送
post '/createrecruit' do

	params["rec_createtime"] = Time.now.strftime("%Y-%m-%d %H:%M:%S");
	params["rec_status"] = "进行中";

	managers = [];
	params['rec_manager'].each  do |people|
		puts "..."
		puts people
		result = JSON.parse( $db[:db_users].find({"user_name": people}).to_a.first.to_json);
		managers.push( {"user_name": people,"user_head": result['user_head'],"manager_state": "未处理", "manager_des": "未处理" ,"updatetime": params["rec_createtime"] } );
	end
	params["rec_create"] = session[:username];
	params["rec_manager"] = managers;
	puts params;
	$db[:db_recruit].insert_one(params);

	redirect to('/recruit')
end

#删除一条员工招聘信息
post '/deleterecruit' do
	
end

#更新员工招聘信息状态
post '/updaterecruit' do

end






#职员图表信息
post '/getEmployeeAgeChart' do
	#查找18~25岁之间的员工
	result_getage_18_25 = $db[:db_employee].find({"em_age": {"$gte": 18,"$lt": 25} }).to_a.to_json;
	#JSON.parse(result);

	result_getage_25_29 = $db[:db_employee].find({"em_age": {"$gte": 25,"$lte": 29} }).to_a.to_json;

	result_getage_30_40 = $db[:db_employee].find({"em_age": {"$gte": 30, "$lte": 40} }).to_a.to_json;

	result_getage_over_40 = $db[:db_employee].find({"em_age": {"$gt": 40} }).to_a.to_json;


	result = [
		{"age": "18到25岁", "count": JSON.parse(result_getage_18_25).length},
		{"age": "25到29岁", "count": JSON.parse(result_getage_25_29).length},
		{"age": "30到40岁", "count": JSON.parse(result_getage_30_40).length},
		{"age": "大于40岁", "count": JSON.parse(result_getage_over_40).length},
	];

	puts result
	return result.to_a.to_json;
end	

#员工性别比例
post '/getEmployeeSexChart' do
	result_male = $db[:db_employee].find({"em_sex": "男"}).to_a.to_json;

	result_female = $db[:db_employee].find({"em_sex": "女"}).to_a.to_json;

	result = [
		{"sex": "男性比例","count": JSON.parse(result_male).length},
		{"sex": "女性比例","count": JSON.parse(result_female).length}
	];
	return result.to_a.to_json;
end



# 我的日程管理
post '/readschedule' do
	result = $db[:db_users].find( "user_name" => session[:username]).to_a.first.to_json
	resultObj = JSON.parse(result)

	if resultObj['user_schedulelist']
		return resultObj['user_schedulelist'].to_json;
	else
		return {};
	end
end


post '/updateschedule' do
	data = JSON.parse(params[:models]).first;

	scheduleId = data['TaskID'];

	update =  {"user_schedulelist.$.Title": data['Title'] ,"user_schedulelist.$.Start": data['Start'] ,'user_schedulelist.$.End': data['End'], "user_schedulelist.$.Description": data['Description'], "user_schedulelist.$.IsAllDay": data['IsAllDay']} ;

	$db[:db_users].update_one({"user_name" => session[:username],"user_schedulelist.TaskID": scheduleId} ,{"$set": update  } );

	return data.to_json;
end


post '/createschedule' do
	data = JSON.parse(params[:models]).first;
	now=Time.now;
	puts data
	scheduleid = now.to_i.to_s + rand(999999).to_s + session[:username];

	inserdata =  {"TaskID": scheduleid,"Title": data['Title'] ,"Start": data['Start'] ,'End': data['End'], "Description": data['Description'], "IsAllDay": data['IsAllDay']} ;

	$db[:db_users].update_one({"user_name" => session[:username]} ,{"$addToSet": {"user_schedulelist": inserdata }  } );
	
	return inserdata.to_json;
end


post '/destroyschedule' do
	data = JSON.parse(params[:models]).first;
	taskid = data['TaskID'];
	$db[:db_users].update_one( {'user_name': session[:username] } ,{"$pull": {"user_schedulelist": {"TaskID": taskid } } } );

	return 200;
end



#报销管理
get '/reimburse' do
	@current = "finance"
	@active = "reimburse"
	erb :reimburse,:layout => :content_layout #主页共用模板
end


get '/addReimburse' do
	@current = "finance"
	@active = "reimburse"
	erb :addReimburse,:layout => :content_layout #主页共用模板
end

#文件上传
post "/upload" do 
  puts 'get////////'
  puts params
  puts 'get////////'
  puts params["file"][:filename]

  puts params["file"][:tempfile]

  path = "public/uploads/" + params["file"][:filename]
  File.open(path, "wb") do |f|
    f.write(params["file"][:tempfile].read)
  end
  return "The file was successfully uploaded!"
end