local strings = string 
local _M = {} 
_M.url = ngx.var.request_uri
 
 --[[
 * 显示分类
 * @access public
 * @param int page 当前页
 * @param int total 总记录数
 * @param int pageSize 每页记录数
 * @param string url 当前网址
 * @return void
--]]
function showPage(currpage, total, pageSize, url)  
    local total = tonumber(total)
    local currpage = tonumber(currpage)
    local pageSize = tonumber(pageSize)
  
    local pageCount
    local pageCount = (total <= pageSize) and 1 or (res) --得到页数
    if (total <= pageSize) then 
        pageCount = 1
    else
        pageCount = math.ceil(total / pageSize)
    end
     
    local currpage = (currpage > pageCount) and pageCount or currpage  --当前页大于  总的分页数
    local currpage = math.max(1, currpage)
    local url = _M._getUrl(url)
    
    local t = {}
    t['num'] = {}
    t['page'] = currpage
    t['pagecount'] = pageCount
    t['total'] = total
    t['url'] = url
    t['limit'] = ((currpage - 1) * pageSize) .. ',' .. pageSize
  
    t['home'] = _M._getPage(url, 1)
    t['prev'] = currpage == 1 and '' or _M._getPage(url, currpage - 1)
    t['end'] = _M._getPage(url, pageCount)
    t['next'] = (currpage == pageCount) and '' or _M._getPage(url, currpage + 1)
    local num = 3
    local startPage = (currpage - num) > 0 and (currpage - 3) or 1
    local endPage = nil
  
    if (currpage < num) then 
        startPage = 1
        endPage = num * 2 
    elseif (currpage + num >= pageCount) then 
        endPage = pageCount
        startPage = currpage - (num * 2 - (pageCount - currpage))
        startPage = math.max(1, startPage) 
    else 
        endPage = currpage + 3
    end 
    endPage = math.min(pageCount, endPage)
   
    while startPage <= endPage do
        t['num'][startPage] = _M._getPage(url, startPage) 
        startPage = startPage + 1
    end
    return t 
end

--[[ 
 * 得到分页信息
 * @access public
 * @param int $total 总记录数
 * @param int $pageSize 每页记录数
 * @param int $page 当前页数
 * @return string 
--]]
function _M.get(total_count, pagesize, currpage, getParameter) 
    _M.getParameter = getParameter or nil;
   
    if (total_count == nil) or (total_count < 1) then 
        return nil 
    end 
    
    local currpage = currpage and tonumber(currpage) or 0  
    return showPage(currpage, total_count,pagesize, ngx.var.request_uri)
end

 --[[
 * 得到当前网址
 * @access public
 * @return string
--]]
function _M._getUrl(url) 
    local get_args  = _M.getParameter
    local i = 0 

    for k,v in pairs(get_args) do  
          i = i + 1 
    end 

    local new_url;
    if i > 0 then
         url,n,err = ngx.re.gsub(url, "(&?page=[^&]*)", "", "i")
         new_url = url .. "&page"  
    else 
         new_url = url .. '?page'
    end 

    return new_url .. '={p}' 
end

--[[
 * 替换%s为页数，从而得到完整的网址
 * @access public
 * @param int $page 页数
 * @return string
--]]
function _M._getPage(url, num)
    return ngx.re.sub(url,"{p}", num, "i") 
end  
return _M
