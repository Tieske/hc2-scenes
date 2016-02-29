--[[
%% properties

%% globals
--]]


-- NEEDS work, doesn't work !!

local selfhttp = net.HTTPClient({timeout=2000}) 
local self_ip = "192.168.0.2"
local usr = "admin"
local pwd = "mypwd"
local url = ("http://%s:%s@%s/api/globalVariables"):format(usr,pwd,self_ip)
local requestBody =  '{"name":"exampleGlobal","value":"123"}'

fibaro:debug(url)
  
selfhttp:request(url, {  
  options={ 
    headers = {
      ["X-Fibaro-Version"] = "2"
    }, 
    data = requestBody, 
    method ='POST', 
    timeout =5000
  }, 
  success = function(status)
      for k,v in pairs(status) do 
        fibaro:debug(tostring(k)..":"..tostring(v))
      end
      for k,v in pairs(status.headers) do 
        fibaro:debug("H "..tostring(k)..":"..tostring(v))
      end
    local result = json.decode(status.data);
    print("status");
    if result.status ==1 then
      print("successful");
      print("Request: "..result.request);
    else
      print("failed");
      print(status.data);
    end
  end, 
  error = function(error)
    print"ERROR"
    print(error)
  end
})
