MY = MY or {}
local _MY = {
    szIniFileEditBox = "Interface\\MY\\.Framework\\ui\\WndEditBox.ini",
    szIniFileButton = "Interface\\MY\\.Framework\\ui\\WndButton.ini",
    szIniFileCheckBox = "Interface\\MY\\.Framework\\ui\\WndCheckBox.ini",
    szIniFileMainPanel = "Interface\\MY\\.Framework\\ui\\MainPanel.ini",
}
local _L = MY.LoadLangPack()
---------------------------------------------------------------------
-- ���ص� UI �������
---------------------------------------------------------------------
-------------------------------------
-- UI object class
-------------------------------------
_MY.UI = class()

-- ������Ԫ�� (�s�F����)�s��ߩ���
-- -- ����Ԫ�����������Ե���table���ã���Ч���൱�� .eles[i].raw
-- setmetatable(_MY.UI, {  __call = function(me, ...) return me:ctor(...) end, __index = function(t, k) 
    -- if type(k) == "number" then
        -- return t.eles[k].raw
    -- elseif k=="new" then
        -- return t['ctor']
    -- end
-- end
-- , __metatable = true 
-- })

-----------------------------------------------------------
-- my ui common functions
-----------------------------------------------------------
-- ��ȡһ�������������Ԫ��
local GetChildren = function(root)
    if not root then return {} end
    local stack = { root }  -- ��ʼջ
    local children = {}     -- ����������Ԫ�� szTreePath => element ��ֵ��
    while #stack > 0 do     -- ѭ��ֱ��ջ��
        --### ��ջ: ����ջ��Ԫ��
        local raw = stack[#stack]
        table.remove(stack, #stack)
        if raw:GetType()=="Handle" then
            -- ����ǰ������Handle������Ԫ�ر�
            children[table.concat({ raw:GetTreePath(), '/Handle' })] = raw
            for i = 0, raw:GetItemCount() - 1, 1 do
                -- �����Ԫ����Handle/����ѹջ
                if raw:Lookup(i):GetType()=='Handle' then table.insert(stack, raw:Lookup(i))
                -- ����ѹ��������
                else children[table.concat({ raw:Lookup(i):GetTreePath(), i })] = raw:Lookup(i) end
            end
        else
            -- �����Handle������Handleѹջ������
            local status, handle = pcall(function() return raw:Lookup('','') end) -- raw����û��Lookup���� ��pcall����
            if status and handle then table.insert(stack, handle) end
            -- ����ǰ������Ԫ�ؼ�����Ԫ�ر�
            children[table.concat({ raw:GetTreePath() })] = raw
            --### ѹջ: ���ոյ�ջ��Ԫ�ص������Ӵ���ѹջ
            local status, sub_raw = pcall(function() return raw:GetFirstChild() end) -- raw����û��GetFirstChild���� ��pcall����
            while status and sub_raw do
                table.insert(stack, sub_raw)
                sub_raw = sub_raw:GetNext()
            end
        end
    end
    -- ��Ϊ������Ԫ�� �����Ƴ���һ��ѹջ��Ԫ�أ���Ԫ�أ�
    children[table.concat({ root:GetTreePath() })] = nil
    return children
end

-----------------------------------------------------------
-- my ui selectors -- same as jQuery -- by tinymins --
-----------------------------------------------------------
--
-- self.ele       : ui elements table
-- selt.ele[].raw : ui element itself    -- common functions will do with this
-- self.ele[].txt : ui element text box  -- functions like Text() will do with this
-- self.ele[].img : ui element image box -- functions like LoadImage() will do with this
--
-- ui object creator 
-- same as jQuery.$()
function _MY.UI:ctor(raw, tab)
    self.eles = self.eles or {}
    if type(raw)=="table" and type(raw.eles)=="table" then
        for i = 1, #raw.eles, 1 do
            table.insert(self.eles, raw.eles[i])
        end
        self.eles = raw.eles
    else
        -- farmat raw
        if type(raw)=="string" then raw = Station.Lookup(raw) end
        -- format tab
        local _tab = { raw = raw }
        if type(tab)=="table" then for k, v in pairs(tab) do _tab[k]=v end end
        local szType = raw.szMyuiType or raw:GetType()
        if not _tab.txt and szType == "Text"        then _tab.txt = raw end
        if not _tab.img and szType == "Image"       then _tab.img = raw end
        if not _tab.chk and szType == "WndCheckBox" then _tab.chk = raw end
        if not _tab.edt and szType == "WndEdit"     then _tab.edt = raw end
        if not _tab.sdw and szType == "Shadow"      then _tab.sdw = raw end
        if not _tab.hdl and szType == "Handle"      then _tab.hdl = raw end
        if not _tab.frm and szType == "WndFrame"    then _tab.frm = raw end
        if szType=="WndEditBox" then
            _tab.wnd = _tab.wnd or raw
            _tab.hdl = _tab.hdl or raw:Lookup('','')
            _tab.edt = _tab.edt or raw:Lookup('WndEdit_Default')
            _tab.img = _tab.img or raw:Lookup('','Image_Default')
        elseif szType=="WndComboBox" then
            _tab.wnd = _tab.wnd or raw
            _tab.hdl = _tab.hdl or raw:Lookup('','')
            _tab.cmb = _tab.cmb or raw:Lookup('Btn_ComboBox')
            _tab.txt = _tab.txt or raw:Lookup('','Text_Default')
            _tab.img = _tab.img or raw:Lookup('','Image_Default')
        elseif szType=="WndEditComboBox" then
            _tab.wnd = _tab.wnd or raw
            _tab.hdl = _tab.hdl or raw:Lookup('','')
            _tab.cmb = _tab.cmb or raw:Lookup('Btn_ComboBox')
            _tab.edt = _tab.edt or raw:Lookup('WndEdit_Default')
            _tab.img = _tab.img or raw:Lookup('','Image_Default')
        elseif szType=="WndScrollBox" then
            _tab.wnd = _tab.wnd or raw
            _tab.hdl = _tab.hdl or raw:Lookup('','Handle_Scroll')
            _tab.txt = _tab.txt or raw:Lookup('','Handle_Scroll'):Lookup('Text_Default')
            _tab.img = _tab.img or raw:Lookup('','Image_Default')
            _tab.sbu = _tab.sbu or raw:Lookup('WndButton_Up')
            _tab.sbd = _tab.sbd or raw:Lookup('WndButton_Down')
            _tab.sbn = _tab.sbn or raw:Lookup('WndNewScrollBar_Default')
            _tab.shd = _tab.shd or raw:Lookup('','Handle_Scroll')
        elseif string.sub(szType, 1, 3) == "Wnd" then
            _tab.wnd = _tab.wnd or raw
            _tab.hdl = _tab.hdl or raw:Lookup('','')
            _tab.txt = _tab.txt or raw:Lookup('','Text_Default')
        else _tab.itm = raw end
        if raw then table.insert( self.eles, _tab ) end
    end
    return self
end

-- clone
-- clone and return a new class
function _MY.UI:clone(eles)
    self:_checksum()
    eles = eles or self.eles
    local _eles = {}
    for i = 1, #eles, 1 do
        if eles[i].raw then table.insert(_eles, self:raw2ele(eles[i].raw)) end
    end
    return _MY.UI.new({eles = _eles})
end

-- conv raw to eles array
function _MY.UI:raw2ele(raw, tab)
    -- format tab
    local _tab = { raw = raw }
    if type(tab)=="table" then for k, v in pairs(tab) do _tab[k]=v end end
    local szType = raw.szMyuiType or raw:GetType()
    if not _tab.txt and szType == "Text"        then _tab.txt = raw end
    if not _tab.img and szType == "Image"       then _tab.img = raw end
    if not _tab.chk and szType == "WndCheckBox" then _tab.chk = raw end
    if not _tab.edt and szType == "WndEdit"     then _tab.edt = raw end
    if not _tab.sdw and szType == "Shadow"      then _tab.sdw = raw end
    if not _tab.hdl and szType == "Handle"      then _tab.hdl = raw end
    if not _tab.frm and szType == "WndFrame"    then _tab.frm = raw end
    if szType=="WndEditBox" then
        _tab.wnd = _tab.wnd or raw
        _tab.hdl = _tab.hdl or raw:Lookup('','')
        _tab.edt = _tab.edt or raw:Lookup('WndEdit_Default')
        _tab.img = _tab.img or raw:Lookup('','Image_Default')
    elseif szType=="WndComboBox" then
        _tab.wnd = _tab.wnd or raw
        _tab.hdl = _tab.hdl or raw:Lookup('','')
        _tab.cmb = _tab.cmb or raw:Lookup('Btn_ComboBox')
        _tab.txt = _tab.txt or raw:Lookup('','Text_Default')
        _tab.img = _tab.img or raw:Lookup('','Image_Default')
    elseif szType=="WndEditComboBox" then
        _tab.wnd = _tab.wnd or raw
        _tab.hdl = _tab.hdl or raw:Lookup('','')
        _tab.cmb = _tab.cmb or raw:Lookup('Btn_ComboBox')
        _tab.edt = _tab.edt or raw:Lookup('WndEdit_Default')
        _tab.img = _tab.img or raw:Lookup('','Image_Default')
    elseif szType=="WndScrollBox" then
        _tab.wnd = _tab.wnd or raw
        _tab.hdl = _tab.hdl or raw:Lookup('','Handle_Scroll')
        _tab.txt = _tab.txt or raw:Lookup('','Handle_Scroll'):Lookup('Text_Default')
        _tab.img = _tab.img or raw:Lookup('','Image_Default')
        _tab.sbu = _tab.sbu or raw:Lookup('WndButton_Up')
        _tab.sbd = _tab.sbd or raw:Lookup('WndButton_Down')
        _tab.sbn = _tab.sbn or raw:Lookup('WndNewScrollBar_Default')
        _tab.shd = _tab.shd or raw:Lookup('','Handle_Scroll')
    elseif string.sub(szType, 1, 3) == "Wnd" then
        _tab.wnd = _tab.wnd or raw
        _tab.hdl = _tab.hdl or raw:Lookup('','')
        _tab.txt = _tab.txt or raw:Lookup('','Text_Default')
    else _tab.itm = raw end
    return _tab
end

--  del bad eles
-- (self) _checksum()
function _MY.UI:_checksum()
    for i = #self.eles, 1, -1 do
        local ele = self.eles[i]
        local status, err = true, 'szType'
        if not ele.raw then
            status, err = false, ''
        else
            status, err = pcall(function() return ele.raw:GetType() end)
        end
        if (not status) or (err=='') then table.remove(self.eles, i) end
    end
    return self
end

-- add a ele to object
-- same as jQuery.add()
function _MY.UI:add(raw, tab)
    self:_checksum()
    local eles = {}
    for i = 1, #self.eles, 1 do
        table.insert(eles, self.eles[i])
    end
    -- farmat raw
    if type(raw)=="string" then raw = Station.Lookup(raw) end
    -- insert into eles
    if raw then table.insert( eles, self:raw2ele(raw, tab) ) end
    return self:clone(eles)
end

-- delete elements from object
-- same as jQuery.not()
function _MY.UI:del(raw)
    self:_checksum()
    local eles = {}
    for i = 1, #self.eles, 1 do
        table.insert(eles, self.eles[i])
    end
    if type(raw) == "string" then
        -- delete ele those id/class fits filter:raw
        if string.sub(raw, 1, 1) == "#" then
            raw = string.sub(raw, 2)
            if string.sub(raw, 1, 1) == "^" then
                -- regexp
                for i = #eles, 1, -1 do
                    if string.find(eles[i].raw:GetName(), raw) then
                        table.remove(eles, i)
                    end
                end
            else
                -- normal
                for i = #eles, 1, -1 do
                    if eles[i].raw:GetName() == raw then
                        table.remove(eles, i)
                    end
                end
            end
        elseif string.sub(raw, 1, 1) == "." then
            raw = string.sub(raw, 2)
            if string.sub(raw, 1, 1) == "^" then
                -- regexp
                for i = #eles, 1, -1 do
                    if string.find((eles[i].raw.szMyuiType or eles[i].raw:GetType()), raw) then
                        table.remove(eles, i)
                    end
                end
            else
                -- normal
                for i = #eles, 1, -1 do
                    if (eles[i].raw.szMyuiType or eles[i].raw:GetType()) == raw then
                        table.remove(eles, i)
                    end
                end
            end
        end
    else
        -- delete ele those treepath is the same as raw
        raw = table.concat({ raw:GetTreePath() })
        for i = #eles, 1, -1 do
            if table.concat({ eles[i].raw:GetTreePath() }) == raw then
                table.remove(eles, i)
            end
        end
    end
    return self:clone(eles)
end

-- filter elements from object
-- same as jQuery.filter()
function _MY.UI:filter(raw)
    self:_checksum()
    local eles = {}
    for i = 1, #self.eles, 1 do
        table.insert(eles, self.eles[i])
    end
    if type(raw) == "string" then
        -- delete ele those id/class not fits filter:raw
        if string.sub(raw, 1, 1) == "#" then
            raw = string.sub(raw, 2)
            if string.sub(raw, 1, 1) == "^" then
                -- regexp
                for i = #eles, 1, -1 do
                    if not string.find(eles[i].raw:GetName(), raw) then
                        table.remove(eles, i)
                    end
                end
            else
                -- normal
                for i = #eles, 1, -1 do
                    if eles[i].raw:GetName() ~= raw then
                        table.remove(eles, i)
                    end
                end
            end
        elseif string.sub(raw, 1, 1) == "." then
            raw = string.sub(raw, 2)
            if string.sub(raw, 1, 1) == "^" then
                -- regexp
                for i = #eles, 1, -1 do
                    if not string.find((eles[i].raw.szMyuiType or eles[i].raw:GetType()), raw) then
                        table.remove(eles, i)
                    end
                end
            else
                -- normal
                for i = #eles, 1, -1 do
                    if (eles[i].raw.szMyuiType or eles[i].raw:GetType()) ~= raw then
                        table.remove(eles, i)
                    end
                end
            end
        end
    elseif type(raw)=="nil" then
        return self
    else
        -- delete ele those treepath is not the same as raw
        raw = table.concat({ raw:GetTreePath() })
        for i = #eles, 1, -1 do
            if table.concat({ eles[i].raw:GetTreePath() }) ~= raw then
                table.remove(eles, i)
            end
        end
    end
    return self:clone(eles)
end

-- get parent
-- same as jQuery.parent()
function _MY.UI:parent()
    self:_checksum()
    local parent = {}
    for _, ele in pairs(self.eles) do
        parent[table.concat{ele.raw:GetParent():GetTreePath()}] = ele.raw:GetParent()
    end
    local eles = {}
    for _, raw in pairs(parent) do
        -- insert into eles
        table.insert( eles, self:raw2ele(raw) )
    end
    return self:clone(eles)
end

-- get child
-- same as jQuery.child()
function _MY.UI:child(filter)
    self:_checksum()
    local child = {}
    local childHash = {}
    for _, ele in pairs(self.eles) do
        if ele.raw:GetType() == "Handle" then
            for i = 0, ele.raw:GetItemCount() - 1, 1 do
                if not childHash[table.concat({ ele.raw:Lookup(i):GetTreePath(), i })] then
                    table.insert(child, ele.raw:Lookup(i))
                    childHash[table.concat({ ele.raw:Lookup(i):GetTreePath(), i })] = true
                end
            end
        else
            -- ��handle
            local status, handle = pcall(function() return ele.raw:Lookup('','') end) -- raw����û��Lookup���� ��pcall����
            if status and handle and not childHash[table.concat{handle:GetTreePath(),'/Handle'}] then
                table.insert(child, handle)
                childHash[table.concat({handle:GetTreePath(),'/Handle'})] = true
            end
            -- �Ӵ���
            local status, sub_raw = pcall(function() return ele.raw:GetFirstChild() end) -- raw����û��GetFirstChild���� ��pcall����
            while status and sub_raw do
                if not childHash[table.concat{sub_raw:GetTreePath()}] then
                    table.insert( child, sub_raw )
                    childHash[table.concat({sub_raw:GetTreePath()})] = true
                end
                sub_raw = sub_raw:GetNext()
            end
        end
    end
    local eles = {}
    for _, raw in ipairs(child) do
        -- insert into eles
        table.insert( eles, self:raw2ele(raw) )
    end
    return self:clone(eles):filter(filter)
end

-- get all children
-- same as jQuery.children(filter)
function _MY.UI:children(filter)
    self:_checksum()
    local children = {}
    for _, ele in pairs(self.eles) do
        if ele.raw then for szTreePath, raw in pairs(GetChildren(ele.raw)) do
            children[szTreePath] = raw
        end end
    end
    local eles = {}
    for _, raw in pairs(children) do
        -- insert into eles
        table.insert( eles, self:raw2ele(raw) )
    end
    return self:clone(eles):filter(filter)
end

-- find ele
-- same as jQuery.find()
function _MY.UI:find(filter)
    return self:children():filter(filter)
end

-- each
-- same as jQuery.each(function(){})
-- :each(_MY.UI each_self)  -- you can use 'this' to visit raw element likes jQuery
function _MY.UI:each(fn)
    self:_checksum()
    local eles = self.eles
    for _, ele in pairs(eles) do
        local _this = this
        this = ele.raw
        pcall(fn, self:clone({{raw = ele.raw}}))
        this = _this
    end
    return self
end

-- eq
-- same as jQuery.eq(pos)
function _MY.UI:eq(pos)
    if pos then
        return self:slice(pos,pos)
    end
    return self
end

-- first
-- same as jQuery.first()
function _MY.UI:first()
    return self:slice(1,1)
end

-- last
-- same as jQuery.last()
function _MY.UI:last()
    return self:slice(-1,-1)
end

-- slice -- index starts from 1
-- same as jQuery.slice(selector, pos)
function _MY.UI:slice(startpos, endpos)
    self:_checksum()
    local eles = {}
    for i = 1, #self.eles, 1 do
        table.insert(eles, self.eles[i])
    end
    endpos = endpos or #eles
    if endpos < 0 then endpos = #eles + endpos + 1 end
    for i = #eles, endpos + 1, -1 do
        table.remove(eles)
    end
    if startpos < 0 then startpos = #eles + startpos + 1 end
    for i = startpos, 2, -1 do
        table.remove(eles, 1)
    end
    return self:clone(eles)
end

-- get raw
-- same as jQuery[index]
function _MY.UI:raw(index, key)
    self:_checksum()
    key = key or 'raw'
    local eles = self.eles
    if index < 0 then index = #eles + index + 1 end
    if index > 0 and index <= #eles then return eles[index][key] end
end

-- get ele
function _MY.UI:ele(index)
    self:_checksum()
    local eles, ele = self.eles, {}
    if index < 0 then index = #eles + index + 1 end
    if index > 0 and index <= #eles then 
        for k, v in pairs(eles[index]) do
            ele[k] = v
        end
    end
    return ele
end

-- get frm
function _MY.UI:frm(index)
    self:_checksum()
    local eles = {}
    if index < 0 then index = #self.eles + index + 1 end
    if index > 0 and index <= #self.eles and self.eles[index].frm then
        table.insert(eles, { raw = self.eles[index].frm })
    end
    return self:clone(eles)
end

-- get wnd
function _MY.UI:wnd(index)
    self:_checksum()
    local eles = {}
    if index < 0 then index = #self.eles + index + 1 end
    if index > 0 and index <= #self.eles and self.eles[index].wnd then
        table.insert(eles, { raw = self.eles[index].wnd })
    end
    return self:clone(eles)
end

-- get item
function _MY.UI:itm(index)
    self:_checksum()
    local eles = {}
    if index < 0 then index = #eles + index + 1 end
    if index > 0 and index <= #self.eles and self.eles[index].itm then
        table.insert(eles, { raw = self.eles[index].itm })
    end
    return self:clone(eles)
end

-- get handle
function _MY.UI:hdl(index)
    self:_checksum()
    local eles = {}
    if index < 0 then index = #eles + index + 1 end
    if index > 0 and index <= #self.eles and self.eles[index].hdl then
        table.insert(eles, { raw = self.eles[index].hdl })
    end
    return self:clone(eles)
end

-----------------------------------------------------------
-- my ui opreation -- same as jQuery -- by tinymins --
-----------------------------------------------------------

-- remove
-- same as jQuery.remove()
function _MY.UI:remove()
    self:_checksum()
    for _, ele in pairs(self.eles) do
        pcall(function() ele.fnDestroy(ele.raw) end)
        if ele.raw:GetType() == "WndFrame" then
            Wnd.CloseWindow(ele.raw)
        elseif string.sub(ele.raw:GetType(), 1, 3) == "Wnd" then
            ele.raw:Destroy()
        else
            pcall(function() ele.raw:GetParent():RemoveItem(ele.raw:GetIndex()) end)
        end
    end
    self.eles = {}
    return self
end

-- xml string
_MY.tItemXML = {
	["Text"] = "<text>w=150 h=30 valign=1 font=162 eventid=371 </text>",
	["Image"] = "<image>w=100 h=100 eventid=371 </image>",
	["Box"] = "<box>w=48 h=48 eventid=525311 </text>",
	["Shadow"] = "<shadow>w=15 h=15 eventid=277 </shadow>",
	["Handle"] = "<handle>w=10 h=10</handle>",
}
-- append
-- similar as jQuery.append()
-- Instance:append(szName, szType, tArg)
-- Instance:append(szItemString)
function _MY.UI:append(szName, szType, tArg)
    self:_checksum()
    if szType then
        for _, ele in pairs(self.eles) do
            if ( ele.wnd and ( string.sub(szType, 1, 3) == "Wnd" or string.sub(szType, -4) == ".ini" ) ) then
                -- append from ini file
                local szFile = szType
                if string.sub(szType, -4) == ".ini" then
                    szType = string.gsub(szType,".*[/\\]","")
                    szType = string.sub(szType,0,-5)
                else
                    szFile = "interface\\MY\\.Framework\\ui\\" .. szFile .. ".ini"
                end
                local frame = Wnd.OpenWindow(szFile, "MY_TempWnd")
                if not frame then
                    return MY.Debug(_L("unable to open ini file [%s]", szFile)..'\n', 'MY#UI#append', 2)
                end
                local wnd = frame:Lookup(szType)
                if not wnd then
                    MY.Debug(_L("can not find wnd component [%s]", szType)..'\n', 'MY#UI#append', 2)
                else
                    wnd.szMyuiType = szType
                    wnd:SetName(szName)
                    wnd:ChangeRelation(ele.wnd, true, true)
                    if szType == "WndScrollBox" then
                        wnd:Lookup('WndButton_Up').OnLButtonHold = function()
                            wnd:Lookup("WndNewScrollBar_Default"):ScrollPrev(1)
                        end
                        wnd:Lookup('WndButton_Down').OnLButtonHold = function()
                            wnd:Lookup("WndNewScrollBar_Default"):ScrollNext(1)
                        end
                        wnd:Lookup('WndButton_Up').OnLButtonDown = function()
                            wnd:Lookup("WndNewScrollBar_Default"):ScrollPrev(1)
                        end
                        wnd:Lookup('WndButton_Down').OnLButtonDown = function()
                            wnd:Lookup("WndNewScrollBar_Default"):ScrollNext(1)
                        end
                        wnd.OnMouseWheel = function()                                   -- listening Mouse Wheel
                            local nDistance = Station.GetMessageWheelDelta()            -- get distance
                            wnd:Lookup("WndNewScrollBar_Default"):ScrollNext(nDistance) -- wheel scroll position
                            return 1
                        end
                        wnd:Lookup("WndNewScrollBar_Default").OnScrollBarPosChanged = function()
                            local nCurrentValue = this:GetScrollPos()
                            wnd:Lookup("WndButton_Up"):Enable( nCurrentValue ~= 0 )
                            wnd:Lookup("WndButton_Down"):Enable( nCurrentValue ~= this:GetStepCount() )
                            wnd:Lookup("", "Handle_Scroll"):SetItemStartRelPos(0, - nCurrentValue * 10)
                        end
                        wnd.UpdateScroll = function()
                            local hHandle     = wnd:Lookup("", "Handle_Scroll")
                            local hScrollBar  = wnd:Lookup("WndNewScrollBar_Default")
                            local hButtonUp   = wnd:Lookup("WndButton_Up")
                            local hButtonDown = wnd:Lookup("WndButton_Down")
                            local bBottom     = hScrollBar:GetStepCount() == hScrollBar:GetScrollPos()
                            hHandle:FormatAllItemPos()
                            local wA, hA = hHandle:GetAllItemSize()
                            local w, h = hHandle:GetSize()
                            local nStep = (hA - h) / 10
                            if nStep > 0 then
                                hScrollBar:Show()
                                hButtonUp:Show()
                                hButtonDown:Show()
                            else
                                hScrollBar:Hide()
                                hButtonUp:Hide()
                                hButtonDown:Hide()
                            end
                            local wb, hb = hScrollBar:GetSize()
                            local _max = ( 150 > (hb * 1 / 2) and (hb * 1 / 2) ) or 150
                            local _min = ( 50 > hb and (hb * 1 / 3) ) or 50
                            local hs = hb - nStep
                            local hs = ( hs > _max and _max ) or hs
                            local hs = ( hs < _min and _min ) or hs
                            hScrollBar:Lookup("WndButton_Scroll"):SetSize( 15, hs )
                            hScrollBar:SetStepCount(nStep)
                            if bBottom then hScrollBar:SetScrollPos(hScrollBar:GetStepCount()) end
                        end
                        pcall( wnd.UpdateScroll )
                    elseif szType=='WndTrackBar' then
                        wnd:Lookup("Scroll_Track").OnScrollBarPosChanged = function()
                            local nCurrentPercentage = this:GetScrollPos() * 100 / this:GetStepCount()
                            wnd:Lookup("", "Text_Default"):SetText(nCurrentPercentage..'%')
                        end
                        wnd:Lookup("Scroll_Track").OnMouseWheel = function()                                   -- listening Mouse Wheel
                            local nDistance = Station.GetMessageWheelDelta()            -- get distance
                            wnd:Lookup("Scroll_Track"):ScrollNext(-nDistance*2)            -- wheel scroll position
                            return 1
                        end
                        wnd:Lookup("Scroll_Track"):Lookup('Btn_Track').OnMouseWheel = function()               -- listening Mouse Wheel
                            local nDistance = Station.GetMessageWheelDelta()            -- get distance
                            wnd:Lookup("Scroll_Track"):ScrollNext(-nDistance)            -- wheel scroll position
                            return 1
                        end
                    end
                end
                Wnd.CloseWindow(frame)
            elseif ( string.sub(szType, 1, 3) ~= "Wnd" and ele.hdl ) then
                local szXml = _MY.tItemXML[szType]
                local hnd
                if szXml then
                    -- append from xml
                    local nCount = ele.hdl:GetItemCount()
                    ele.hdl:AppendItemFromString(szXml)
                    hnd = ele.hdl:Lookup(nCount)
                    if hnd then hnd:SetName(szName) end
                else
                    -- append from ini
                    hnd = ele.hdl:AppendItemFromIni("interface\\MY\\.Framework\\ui\\HandleItems.ini","Handle_" .. szType, szName)
                end
                ele.hdl:FormatAllItemPos()
                if not hnd then
                    return MY.Debug(_L("unable to append handle item [%s]", szType)..'\n','MY#UI:append',2)
                end
            end
        end
    else
        for _, ele in pairs(self.eles) do
            if ele.hdl then
                -- append from xml
                local nCount = ele.hdl:GetItemCount()
                pcall(function() ele.hdl:AppendItemFromString(szName) end)
                local hnd 
                for i = nCount, ele.hdl:GetItemCount()-1, 1 do
                    hnd = ele.hdl:Lookup(i)
                    if hnd and hnd:GetName()=='' then hnd:SetName('Unnamed_Item'..i) end
                end
                ele.hdl:FormatAllItemPos()
                pcall( ele.raw.UpdateScroll )
                if nCount == ele.hdl:GetItemCount() then
                    return MY.Debug(_L("unable to append handle item from string.")..'\n','MY#UI:append',2)
                end
            end
        end
    end
    return self
end

-- clear
-- clear handle
-- (self) Instance:clear()
function _MY.UI:clear()
    self:_checksum()
    for _, ele in pairs(self.eles) do
        if ele.hdl then
            pcall(function() ele.hdl:Clear() end)
        end
        if ele.sbu then
            ele.raw.UpdateScroll()
        end
    end
    return self
end

-----------------------------------------------------------
-- my ui property visitors
-----------------------------------------------------------

-- data set/get
function _MY.UI:data(key, value)
    self:_checksum()
    if key and value then -- set name
        for _, ele in pairs(self.eles) do
            pcall(function() ele.raw[key] = value end)
        end
        return self
    elseif key then -- get
        -- select the first item
        local ele = self.eles[1]
        -- try to get its name
        local status, err = pcall(function() return ele.raw[key] end)
        -- if succeed then return its name
        if status then return err else MY.Debug(err..'\n','ERROR _MY.UI:data' ,1) return nil end
    else
        return self
    end
end

-- show
function _MY.UI:show()
    self:_checksum()
    for _, ele in pairs(self.eles) do
        pcall(function() ele.raw:Show() end)
        pcall(function() ele.hdl:Show() end)
    end
    return self
end

-- hide
function _MY.UI:hide()
    self:_checksum()
    for _, ele in pairs(self.eles) do
        pcall(function() ele.raw:Hide() end)
        pcall(function() ele.hdl:Hide() end)
    end
    return self
end

-- visiable
function _MY.UI:visiable(bVisiable)
    self:_checksum()
    if type(bVisiable)=='boolean' then
        return self:toggle(bVisiable)
    else -- get
        -- select the first item
        local ele = self.eles[1]
        -- try to get its name
        local status, err = pcall(function() return ele.raw:IsVisible() end)
        -- if succeed then return its name
        if status then return err else MY.Debug(err..'\n','ERROR _MY.UI:visiable' ,1) return nil end
    end
end

-- show/hide eles
function _MY.UI:toggle(bShow)
    self:_checksum()
    for _, ele in pairs(self.eles) do
        pcall(function() if bShow == false or (not bShow and ele.raw:IsVisible()) then ele.raw:Hide() ele.hdl:Hide() else ele.raw:Show() ele.hdl:Show() end end)
    end
    return self
end

-- drag area
-- (self) drag(boolean bEnableDrag) -- enable/disable drag
-- (self) drag(number x, number y, number w, number h) -- set drag positon and area
function _MY.UI:drag(x, y, w, h)
    self:_checksum()
    if type(x) == 'boolean' then
        for _, ele in pairs(self.eles) do
            pcall(function() (ele.frm or ele.raw):EnableDrag(x) end)
        end
        return self
    elseif x or y or w or h then
        for i = 1, #self.eles, 1 do
            local s, err =pcall(function()
                local _w, _h = self:eq(i):size()
                x, y, w, h = x or 0, y or 0, w or _w, h or _h
                self:frm(i):raw(1):SetDragArea(x, y, w, h)
            end)
        end
        return self
    else
        -- select the first item
        local ele = self.eles[1]
        -- try to get its name
        local status, err = pcall(function() return (ele.frm or ele.raw):IsDragable() end)
        -- if succeed then return its name
        if status then return err else MY.Debug(err..'\n','ERROR _MY.UI:drag' ,1) return nil end
    end
end

-- get/set ui object text
function _MY.UI:text(szText)
    self:_checksum()
    if szText then
        for _, ele in pairs(self.eles) do
            pcall(function() (ele.txt or ele.edt or ele.raw):SetText(szText) end)
            pcall(function() (ele.txt or ele.edt or ele.raw):GetParent():FormatAllItemPos() end)
            if ele.sbu then
                ele.raw.UpdateScroll()
            end
        end
        return self
    else
        -- select the first item
        local ele = self.eles[1]
        -- try to get its name
        local status, err = pcall(function() return (ele.txt or ele.edt or ele.raw):GetText() end)
        -- if succeed then return its name
        if status then return err else MY.Debug(err..'\n','ERROR _MY.UI:text' ,3) return nil end
    end
end

-- get/set ui object name
function _MY.UI:name(szText)
    self:_checksum()
    if szText then -- set name
        for _, ele in pairs(self.eles) do
            pcall(function() ele.raw:SetName(szText) end)
        end
        return self
    else -- get
        -- select the first item
        local ele = self.eles[1]
        -- try to get its name
        local status, err = pcall(function() return ele.raw:GetName() end)
        -- if succeed then return its name
        if status then return err else MY.Debug(err..'\n','ERROR _MY.UI:name' ,3) return nil end
    end
end

-- get/set ui alpha
function _MY.UI:alpha(nAlpha)
    self:_checksum()
    if nAlpha then -- set name
        for _, ele in pairs(self.eles) do
            pcall(function() ele.raw:SetAlpha(nAlpha) end)
        end
        return self
    else -- get
        -- select the first item
        local ele = self.eles[1]
        -- try to get its name
        local status, err = pcall(function() return ele.raw:GetAlpha() end)
        -- if succeed then return its name
        if status then return err else MY.Debug(err..'\n','ERROR _MY.UI:alpha' ,3) return nil end
    end
end

-- (self) Instance:fadeTo(nTime, nOpacity, callback)
function _MY.UI:fadeTo(nTime, nOpacity, callback)
    self:_checksum()
    if nTime and nOpacity then
        for i = 1, #self.eles, 1 do
            local ele = self:eq(i)
            local nStartAlpha = ele:alpha()
            local nStartTime = GetTime()
            local fnCurrent = function(nStart, nEnd, nTotalTime, nDuringTime)
                return ( nEnd - nStart ) * nDuringTime / nTotalTime + nStart -- ����ģ��
            end
            if not ele:visiable() then ele:alpha(0):toggle(true) end
            MY.BreatheCall(function() 
                ele:show()
                local nCurrentAlpha = fnCurrent(nStartAlpha, nOpacity, nTime, GetTime()-nStartTime)
                ele:alpha(nCurrentAlpha)
                -- MY.Debug(string.format('%d %d %d %d\n', nStartAlpha, nOpacity, nCurrentAlpha, (nStartAlpha - nCurrentAlpha)*(nCurrentAlpha - nOpacity)), 'fade', 0)
                if (nStartAlpha - nCurrentAlpha)*(nCurrentAlpha - nOpacity) <= 0 then
                    ele:alpha(nOpacity):toggle(nOpacity ~= 0)
                    pcall(callback)
                    return 0
                end
            end)
        end
    end
    return self
end

-- (self) Instance:fadeIn(nTime, callback)
function _MY.UI:fadeIn(nTime, callback)
    self:_checksum()
    nTime = nTime or 300
    for i = 1, #self.eles, 1 do
        self:eq(i):fadeTo(nTime, self:eq(i):data('nOpacity') or 255, callback)
    end
    return self
end

-- (self) Instance:fadeOut(nTime, callback)
function _MY.UI:fadeOut(nTime, callback)
    self:_checksum()
    nTime = nTime or 300
    for i = 1, #self.eles, 1 do
        local ele = self:eq(i)
        if ele:alpha() > 0 then ele:data('nOpacity', ele:alpha()) end
    end
    self:fadeTo(nTime, 0, callback)
    return self
end

-- (self) Instance:slideTo(nTime, nHeight, callback)
function _MY.UI:slideTo(nTime, nHeight, callback)
    self:_checksum()
    if nTime and nHeight then
        for i = 1, #self.eles, 1 do
            local ele = self:eq(i)
            local nStartValue = ele:height()
            local nStartTime = GetTime()
            local fnCurrent = function(nStart, nEnd, nTotalTime, nDuringTime)
                return ( nEnd - nStart ) * nDuringTime / nTotalTime + nStart -- ����ģ��
            end
            if not ele:visiable() then ele:height(0):toggle(true) end
            MY.BreatheCall(function() 
                ele:show()
                local nCurrentValue = fnCurrent(nStartValue, nHeight, nTime, GetTime()-nStartTime)
                ele:height(nCurrentValue)
                -- MY.Debug(string.format('%d %d %d %d\n', nStartValue, nHeight, nCurrentValue, (nStartValue - nCurrentValue)*(nCurrentValue - nHeight)), 'slide', 0)
                if (nStartValue - nCurrentValue)*(nCurrentValue - nHeight) <= 0 then
                    ele:height(nHeight):toggle( nHeight ~= 0 )
                    pcall(callback)
                    return 0
                end
            end)
        end
    end
    return self
end

-- (self) Instance:slideUp(nTime, callback)
function _MY.UI:slideUp(nTime, callback)
    self:_checksum()
    nTime = nTime or 300
    for i = 1, #self.eles, 1 do
        local ele = self:eq(i)
        if ele:height() > 0 then ele:data('nSlideTo', ele:height()) end
    end
    self:slideTo(nTime, 0, callback)
    return self
end

-- (self) Instance:slideDown(nTime, callback)
function _MY.UI:slideDown(nTime, callback)
    self:_checksum()
    nTime = nTime or 300
    for i = 1, #self.eles, 1 do
        self:eq(i):slideTo(nTime, self:eq(i):data('nSlideTo'), callback)
    end
    return self
end

-- (number) Instance:font()
-- (self) Instance:font(number nFont)
function _MY.UI:font(nFont)
    self:_checksum()
    if nFont then-- set name
        for _, ele in pairs(self.eles) do
            pcall(function() ele.raw:SetFontScheme(nFont) end)
        end
        return self
    else -- get
        -- select the first item
        local ele = self.eles[1]
        -- try to get its name
        local status, err = pcall(function() return ele.raw:GetFontScheme() end)
        -- if succeed then return its name
        if status then return err else MY.Debug(err..'\n','ERROR _MY.UI:font' ,3) return nil end
    end
end

-- (number, number, number) Instance:color()
-- (self) Instance:color(number nRed, number nGreen, number nBlue)
function _MY.UI:color(nRed, nGreen, nBlue)
    self:_checksum()
    if type(nRed) == "table" then
        nBlue = nRed[3]
        nGreen = nRed[2]
        nRed = nRed[1]
    end
    if nBlue then
        for _, ele in pairs(self.eles) do
            pcall(function() ele.sdw:SetColorRGB(nRed, nGreen, nBlue) end)
            pcall(function() (ele.edt or ele.txt):SetFontColor(nRed, nGreen, nBlue) end)
        end
        return self
    else -- get
        -- select the first item
        local ele = self.eles[1]
        -- try to get its name
        local status, r,g,b = pcall(function() if ele.sdw then return ele.sdw:GetColorRGB() else return (ele.edt or ele.txt):GetFontColor() end end)
        -- if succeed then return its name
        if status then return r,g,b else MY.Debug(r..'\n','ERROR _MY.UI:color' ,3) return nil end
    end
end

-- (number) Instance:left()
-- (self) Instance:left(number)
function _MY.UI:left(nLeft)
    if nLeft then
        return self:pos(nLeft, nil)
    else
        local l, t = self:pos()
        return l
    end
end

-- (number) Instance:top()
-- (self) Instance:top(number)
function _MY.UI:top(nTop)
    if nTop then
        return self:pos(nil, nTop)
    else
        local l, t = self:pos()
        return t
    end
end

-- (number, number) Instance:pos()
-- (self) Instance:pos(nLeft, nTop)
function _MY.UI:pos(nLeft, nTop)
    self:_checksum()
    if nLeft or nTop then
        for _, ele in pairs(self.eles) do
            local _nLeft, _nTop = ele.raw:GetRelPos()
            nLeft, nTop = nLeft or _nLeft, nTop or _nTop
            if ele.wnd then
                pcall(function() (ele.wnd or ele.raw):SetRelPos(nLeft, nTop) end)
            elseif ele.itm then
                pcall(function() (ele.itm or ele.raw):SetRelPos(nLeft, nTop) end)
                pcall(function() (ele.itm or ele.raw):GetParent():FormatAllItemPos() end)
            end
        end
        return self
    else -- get
        -- select the first item
        local ele = self.eles[1]
        -- try to get its name
        local status, l, t = pcall(function() return ele.raw:GetRelPos() end)
        -- if succeed then return its name
        if status then return l, t else MY.Debug(l..'\n','ERROR _MY.UI:left|top|pos' ,1) return nil end
    end
end

-- (number) Instance:width()
-- (self) Instance:width(number)
function _MY.UI:width(nWidth)
    if nWidth then
        return self:size(nWidth, nil)
    else
        local w, h = self:size()
        return w
    end
end

-- (number) Instance:height()
-- (self) Instance:height(number)
function _MY.UI:height(nHeight)
    if nHeight then
        return self:size(nil, nHeight)
    else
        local w, h = self:size()
        return h
    end
end

-- (number, number) Instance:size()
-- (self) Instance:size(nLeft, nTop)
function _MY.UI:size(nWidth, nHeight)
    self:_checksum()
    if nWidth or nHeight then
        for _, ele in pairs(self.eles) do
            local _nWidth, _nHeight = ele.raw:GetSize()
            nWidth, nHeight = nWidth or _nWidth, nHeight or _nHeight
            if ele.wnd then
                pcall(function() ele.wnd:SetSize(nWidth, nHeight) end)
                pcall(function() ele.hdl:SetSize(nWidth, nHeight) end)
                pcall(function() ele.txt:SetSize(nWidth, nHeight) end)
                pcall(function() ele.img:SetSize(nWidth, nHeight) end)
                pcall(function() ele.edt:SetSize(nWidth-8, nHeight-4) end)
                pcall(function() local w, h= ele.cmb:GetSize() ele.edt:SetSize(nWidth-10-w, nHeight-4) end)
                pcall(function() local w, h= ele.cmb:GetSize() ele.cmb:SetRelPos(nWidth-w-5, (nHeight-h-1)/2+1) end)
                pcall(function() ele.hdl:FormatAllItemPos() end)
            elseif ele.itm then
                pcall(function() (ele.itm or ele.raw):SetSize(nWidth, nHeight) end)
                pcall(function() (ele.itm or ele.raw):GetParent():FormatAllItemPos() end)
                pcall(function() ele.hdl:FormatAllItemPos() end)
            end
            if ele.sbu then
                ele.sbu:SetRelPos(nWidth-25, 10)
                ele.sbd:SetRelPos(nWidth-25, nHeight-30)
                ele.sbn:SetRelPos(nWidth-21.5, 30)
                ele.sbn:SetSize(15, nHeight-60)
                ele.shd:SetSize(nWidth-35, nHeight-20)
                ele.raw.UpdateScroll()
            end
        end
        return self
    else -- get
        -- select the first item
        local ele = self.eles[1]
        -- try to get its name
        local status, w, h = pcall(function() return ele.raw:GetSize() end)
        -- if succeed then return its name
        if status then return w, h else MY.Debug(w..'\n','ERROR _MY.UI:height|width|size' ,1) return nil end
    end
end

-- (boolean) Instance:multiLine()
-- (self) Instance:multiLine(bMultiLine)
function _MY.UI:multiLine(bMultiLine)
    self:_checksum()
    if type(bMultiLine)=='boolean' then
        for _, ele in pairs(self.eles) do
            pcall(function() ele.edt:SetMultiLine(bMultiLine) end)
            pcall(function() ele.edt:GetParent():FormatAllItemPos() end)
            pcall(function() ele.txt:SetMultiLine(bMultiLine) end)
            pcall(function() ele.txt:GetParent():FormatAllItemPos() end)
        end
        return self
    else -- get
        -- select the first item
        local ele = self.eles[1]
        -- try to get its name
        local status, bMultiLine = pcall(function() return (ele.edt or ele.txt):IsMultiLine() end)
        -- if succeed then return its name
        if status then return bMultiLine else MY.Debug(bMultiLine..'\n','ERROR _MY.UI:multiLine' ,1) return nil end
    end
end

-- (self) Instance:image(szImageAndFrame)
-- (self) Instance:image(szImage, nFrame)
function _MY.UI:image(szImage, nFrame)
    self:_checksum()
    if szImage then
        nFrame = nFrame or string.gsub(szImage, '.*%|(%d+)', '%1')
        szImage = string.gsub(szImage, '%|.*', '')
        if nFrame then
            nFrame = tonumber(nFrame)
            for _, ele in pairs(self.eles) do
                pcall(function() ele.img:FromUITex(szImage, nFrame) end)
                pcall(function() ele.img:GetParent():FormatAllItemPos() end)
            end
        else
            for _, ele in pairs(self.eles) do
                pcall(function() ele.img:FromTextureFile(szImage) end)
                pcall(function() ele.img:GetParent():FormatAllItemPos() end)
            end
        end
    end
    return self
end

-- (self) Instance:handleStyle(dwStyle)
function _MY.UI:handleStyle(dwStyle)
    self:_checksum()
    if dwStyle then
        for _, ele in pairs(self.eles) do
            pcall(function() ele.hdl:SetHandleStyle(dwStyle) end)
        end
    end
    return self
end

-- (self) Instance:bringToTop()
function _MY.UI:bringToTop()
    self:_checksum()
    for _, ele in pairs(self.eles) do
        pcall(function() ele.frm:BringToTop() end)
    end
    return self
end

-- (self) Instance:refresh()
function _MY.UI:refresh()
    self:_checksum()
    for _, ele in pairs(self.eles) do
        if ele.sbu then
            ele.raw.UpdateScroll()
        end
    end
    return self
end

-----------------------------------------------------------
-- my ui events handle
-----------------------------------------------------------

--[[ menu �����˵�
    :menu(table menu)  �����˵�menu
    :menu(functin fn)  �����˵�function����ֵtable
]]
function _MY.UI:menu(lmenu, rmenu, bNoAutoBind)
    self:_checksum()
    if not bNoAutoBind then
        rmenu = rmenu or lmenu
    end
    -- pop menu function
    local fnPopMenu = function(raw, menu)
        local _menu = nil
        local nX, nY = raw:GetAbsPos()
        local nW, nH = raw:GetSize()
        if type(menu) == "function" then
            _menu = menu()
        else
            _menu = menu
        end
        _menu.nMiniWidth = nW
        _menu.x = nX
        _menu.y = nY + nH
        PopupMenu(_menu)
    end
    -- bind left click
    if lmenu then 
        self:each(function(eself)
            eself:lclick(function() fnPopMenu(eself:raw(1), lmenu) end)
        end)
    end
    -- bind right click
    if rmenu then 
        self:each(function(eself)
            eself:rclick(function() fnPopMenu(eself:raw(1), rmenu) end)
        end)
    end
    return self
end

--[[ lmenu ��������˵�
    :lmenu(table menu)  �����˵�menu
    :lmenu(functin fn)  �����˵�function����ֵtable
]]
function _MY.UI:lmenu(menu)
    return self:menu(menu, nil, true)
end

--[[ rmenu �����Ҽ��˵�
    :lmenu(table menu)  �����˵�menu
    :lmenu(functin fn)  �����˵�function����ֵtable
]]
function _MY.UI:rmenu(menu)
    return self:menu(nil, menu, true)
end

--[[ click ��굥���¼�
    same as jQuery.click()
    :click(fnAction) ��
    :click()         ����
    :click(number n) ����
    n: 1    ���
       0    �м�
      -1    �Ҽ�
]]
function _MY.UI:click(fnLClick, fnRClick, fnMClick, bNoAutoBind)
    self:_checksum()
    if type(fnLClick)=="function" or type(fnMClick)=="function" or type(fnRClick)=="function" then
        if not bNoAutoBind then
            fnMClick = fnMClick or fnLClick
            fnRClick = fnRClick or fnLClick
        end
        for _, ele in pairs(self.eles) do
            if type(fnLClick)=="function" then
                if ele.wnd then MY.UI.RegisterUIEvent(ele.wnd ,'OnLButtonClick' , function() fnLClick(MY.Const.Event.Mouse.LBUTTON) end) end
                if ele.itm then MY.UI.RegisterUIEvent(ele.itm ,'OnItemLButtonClick' , function() fnLClick(MY.Const.Event.Mouse.LBUTTON) end) end
                if ele.hdl then MY.UI.RegisterUIEvent(ele.hdl ,'OnItemLButtonClick' , function() fnLClick(MY.Const.Event.Mouse.LBUTTON) end) end
                if ele.cmb then MY.UI.RegisterUIEvent(ele.cmb ,'OnLButtonClick' , function() fnLClick(MY.Const.Event.Mouse.LBUTTON) end) end
            end
            if type(fnMClick)=="function" then
                
            end
            if type(fnRClick)=="function" then
                if ele.wnd then MY.UI.RegisterUIEvent(ele.wnd ,'OnRButtonClick' , function() fnRClick(MY.Const.Event.Mouse.RBUTTON) end) end
                if ele.itm then MY.UI.RegisterUIEvent(ele.itm ,'OnItemRButtonClick' , function() fnRClick(MY.Const.Event.Mouse.RBUTTON) end) end
                if ele.hdl then MY.UI.RegisterUIEvent(ele.hdl ,'OnItemRButtonClick' , function() fnRClick(MY.Const.Event.Mouse.RBUTTON) end) end
                if ele.cmb then MY.UI.RegisterUIEvent(ele.cmb ,'OnRButtonClick' , function() fnRClick(MY.Const.Event.Mouse.RBUTTON) end) end
            end
        end
    else
        local nFlag = fnLClick or fnMClick or fnRClick or MY.Const.Event.Mouse.LBUTTON
        if nFlag==MY.Const.Event.Mouse.LBUTTON then
            for _, ele in pairs(self.eles) do
                if ele.wnd then local _this = this this = ele.wnd pcall(ele.wnd.OnLButtonClick) this = _this end
                if ele.itm then local _this = this this = ele.itm pcall(ele.itm.OnItemLButtonClick) this = _this end
            end
        elseif nFlag==MY.Const.Event.Mouse.MBUTTON then
            
        elseif nFlag==MY.Const.Event.Mouse.RBUTTON then
            for _, ele in pairs(self.eles) do
                if ele.wnd then local _this = this this = ele.wnd pcall(ele.wnd.OnRButtonClick) this = _this end
                if ele.itm then local _this = this this = ele.itm pcall(ele.itm.OnItemRButtonClick) this = _this end
            end
        end
    end
    return self
end

--[[ lclick �����������¼�
    same as jQuery.lclick()
    :lclick(fnAction) ��
    :lclick()         ����
]]
function _MY.UI:lclick(fnLClick)
    return self:click(fnLClick or MY.Const.Event.Mouse.LBUTTON, nil, nil, true)
end

--[[ rclick ����Ҽ������¼�
    same as jQuery.rclick()
    :rclick(fnAction) ��
    :rclick()         ����
]]
function _MY.UI:rclick(fnRClick)
    return self:click(nil, fnRClick or MY.Const.Event.Mouse.RBUTTON, nil, true)
end

--[[ hover �����ͣ�¼�
    same as jQuery.hover()
    :hover(fnHover[, fnLeave]) ��
]]
function _MY.UI:hover(fnHover, fnLeave, bNoAutoBind)
    self:_checksum()
    if not bNoAutoBind then fnLeave = fnLeave or fnHover end
    if fnHover then
        for _, ele in pairs(self.eles) do
            if ele.wnd then MY.UI.RegisterUIEvent(ele.wnd, 'OnMouseEnter' , function() fnHover(true) end) end
            if ele.itm then MY.UI.RegisterUIEvent(ele.itm, 'OnItemMouseEnter', function() fnHover(true) end) end
        end
    end
    if fnLeave then
        for _, ele in pairs(self.eles) do
            if ele.wnd then MY.UI.RegisterUIEvent(ele.wnd, 'OnMouseLeave' , function() fnLeave(true) end) end
            if ele.itm then MY.UI.RegisterUIEvent(ele.itm, 'OnItemMouseLeave', function() fnLeave(true) end) end
        end
    end
    return self
end

--[[ tip �����ͣ��ʾ
    (self) Instance:tip( szTip[, nPosType[, tOffset[, bNoEncode] ] ] ) ��tip�¼�
    string szTip:       Ҫ��ʾ�������ı������л���DOM�ı�
    number nPosType:    ��ʾλ�� ��ЧֵΪMY.Const.UI.Tip.ö��
    table tOffset:      ��ʾ��ƫ�����ȸ�����Ϣ{ x = x, y = y, hide = MY.Const.UI.Tip.Hideö��, nFont = ����, r, g, b = ����ɫ }
    boolean bNoEncode:  ��szTipΪ���ı�ʱ�����������Ϊfalse ��szTipΪ��ʽ����DOM�ַ���ʱ���øò���Ϊtrue
]]
function _MY.UI:tip(szTip, nPosType, tOffset, bNoEncode)
    tOffset = tOffset or {}
    tOffset.x = tOffset.x or 0
    tOffset.y = tOffset.y or 0
    tOffset.w = tOffset.w or 450
    tOffset.hide = tOffset.hide or MY.Const.UI.Tip.HIDE
    tOffset.nFont = tOffset.nFont or 136
    if not bNoEncode then
        szTip = GetFormatText(szTip, tOffset.nFont, tOffset.r, tOffset.g, tOffset.b)
    end
    nPosType = nPosType or MY.Const.UI.Tip.POS_FOLLOW_MOUSE
    return self:hover(function()
        local x, y = this:GetAbsPos()
        local w, h = this:GetSize()
        if nPosType == MY.Const.UI.Tip.POS_FOLLOW_MOUSE then
            x, y = Cursor.GetPos()
            x, y = x - 0, y - 40
        end
        x, y = x + tOffset.x, y + tOffset.y
        OutputTip(szTip, tOffset.w, {x, y, w, h}, nPosType)
    end, function()
        if tOffset.hide == MY.Const.UI.Tip.HIDE then
            HideTip(false)
        elseif tOffset.hide == MY.Const.UI.Tip.ANIMATE_HIDE then
            HideTip(true)
        end
    end, true)
end

--[[ check ��ѡ��״̬�仯
    :check(fnOnCheckBoxCheck[, fnOnCheckBoxUncheck]) ��
    :check()                �����Ƿ��ѹ�ѡ
    :check(bool bChecked)   ��ѡ/ȡ����ѡ
]]
function _MY.UI:check(fnCheck, fnUncheck)
    self:_checksum()
    fnUncheck = fnUncheck or fnCheck
    if type(fnCheck)=="function" then
        for _, ele in pairs(self.eles) do
            if ele.chk then ele.chk.OnCheckBoxCheck = function() fnCheck(true) end end
            if ele.chk then ele.chk.OnCheckBoxUncheck = function() fnUncheck(false) end end
        end
        return self
    elseif type(fnCheck) == "boolean" then
        for _, ele in pairs(self.eles) do
            if ele.chk then ele.chk:Check(fnCheck) end
        end
        return self
    elseif not fnCheck then
        -- select the first item
        local ele = self.eles[1]
        -- try to get its name
        local status, err = pcall(function() return ele.chk:IsCheckBoxChecked() end)
        -- if succeed then return its name
        if status then return err else MY.Debug(err..'\n','ERROR _MY.UI:check' ,1) return nil end
    else
        MY.Debug('fnCheck:'..type(fnCheck)..' fnUncheck:'..type(fnUncheck)..'\n', 'ERROR _MY.UI:check' ,1)
    end
end

--[[ change ��������ֱ仯
    :change(fnOnEditChanged) ��
    :change()   ���ô�������
]]
function _MY.UI:change(fnOnEditChanged)
    self:_checksum()
    if fnOnEditChanged then
        for _, ele in pairs(self.eles) do
            if ele.edt then ele.edt.OnEditChanged = function() pcall(fnOnEditChanged,ele.edt:GetText()) end end
        end
        return self
    else
        for _, ele in pairs(self.eles) do
            if ele.edt then local _this = this this = ele.edt pcall(ele.edt.OnEditChanged) this = _this  end
        end
        return self
    end
end

-- OnGetFocus ��ȡ����

-----------------------------------------------------------
-- MY.UI
-----------------------------------------------------------

MY.UI = MY.UI or {}
MY.Const = MY.Const or {}
MY.Const.Event = MY.Const.Event or {}
MY.Const.Event.Mouse = MY.Const.Event.Mouse or {}
MY.Const.Event.Mouse.LBUTTON = 1
MY.Const.Event.Mouse.MBUTTON = 0
MY.Const.Event.Mouse.RBUTTON = -1
MY.Const.UI = MY.Const.UI or {}
MY.Const.UI.Tip = MY.Const.UI.Tip or {}
MY.Const.UI.Tip.POS_FOLLOW_MOUSE = 0
MY.Const.UI.Tip.POS_LEFT         = 1
MY.Const.UI.Tip.POS_RIGHT        = 2
MY.Const.UI.Tip.POS_TOP          = 3
MY.Const.UI.Tip.POS_BOTTOM       = 4
MY.Const.UI.Tip.POS_RIGHT_BOTTOM = 5

MY.Const.UI.Tip.NO_HIDE      = 100
MY.Const.UI.Tip.HIDE         = 101
MY.Const.UI.Tip.ANIMATE_HIDE = 102

-- ����Ԫ�����������Ե����������ã���Ч���൱�� MY.UI.Fetch
setmetatable(MY.UI, { __call = function(me, ...) return me.Fetch(...) end, __metatable = true })

--[[ ���캯�� ����jQuery: $(selector) ]]
MY.UI.Fetch = function(selector, tab) return _MY.UI.new(selector, tab) end
-- ��UI�¼�
MY.UI.RegisterUIEvent = function(raw, szEvent, fnEvent)
    if not raw['tMy'..szEvent] then
        raw['tMy'..szEvent], raw[szEvent] = { raw[szEvent] }, function() for _, fn in ipairs(this['tMy'..szEvent]) do pcall(fn) end end
    end
    if fnEvent then table.insert(raw['tMy'..szEvent], fnEvent) end
end

-- open new frame
MY.UI.OpenFrame = function(szName, szStyle, bDummyFrame)
    local frm, szDummy = nil, ''
    if bDummyFrame then szDummy = 'Dummy' end
    local szIniFile = "interface\\MY\\.Framework\\ui\\WndFrameNormal"..szDummy..".ini"
    if szStyle=='Topmost' then
        szIniFile = "interface\\MY\\.Framework\\ui\\WndFrameTopmost"..szDummy..".ini"
    elseif szStyle=='Lowest' then
        szIniFile = "interface\\MY\\.Framework\\ui\\WndFrameLowest"..szDummy..".ini"
    else
        szStyle = 'Normal'
    end
    if type(szName) == "string" then
        frm = Station.Lookup(szStyle.."/" .. szName)
        if frm then
            Wnd.CloseWindow(frm)
        end
        frm = Wnd.OpenWindow(szIniFile, szName)
    else
        frm = Wnd.OpenWindow(szIniFile)
    end
    frm:Show()
    return MY.UI(frm)
end

-- �������
MY.UI.OpenInternetExplorer = function(szAddr, bDisableSound)
    local nIndex, nLast = nil, nil
    for i = 1, 10, 1 do
        if not _MY.IsInternetExplorerOpened(i) then
            nIndex = i
            break
        elseif not nLast then
            nLast = i
        end
    end
    if not nIndex then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.MSG_OPEN_TOO_MANY)
        return nil
    end
    local x, y = _MY.IE_GetNewIEFramePos()
    local frame = Wnd.OpenWindow("InternetExplorer", "IE"..nIndex)
    frame.bIE = true
    frame.nIndex = nIndex

    frame:BringToTop()
    if nLast then
        frame:SetAbsPos(x, y)
        frame:CorrectPos()
        frame.x = x
        frame.y = y
    else
        frame:SetPoint("CENTER", 0, 0, "CENTER", 0, 0)
        frame.x, frame.y = frame:GetAbsPos()
    end
    local webPage = frame:Lookup("WebPage_Page")
    if szAddr then
        webPage:Navigate(szAddr)
    end
    Station.SetFocusWindow(webPage)
    if not bDisableSound then
        PlaySound(SOUND.UI_SOUND,g_sound.OpenFrame)
    end
    return webPage
end
-- �ж�������Ƿ��ѿ���
_MY.IsInternetExplorerOpened = function(nIndex)
    local frame = Station.Lookup("Topmost/IE"..nIndex)
    if frame and frame:IsVisible() then
        return true
    end
    return false
end
-- ��ȡ���������λ��
_MY.IE_GetNewIEFramePos = function()
    local nLastTime = 0
    local nLastIndex = nil
    for i = 1, 10, 1 do
        local frame = Station.Lookup("Topmost/IE"..i)
        if frame and frame:IsVisible() then
            if frame.nOpenTime > nLastTime then
                nLastTime = frame.nOpenTime
                nLastIndex = i
            end
        end
    end
    if nLastIndex then
        local frame = Station.Lookup("Topmost/IE"..nLastIndex)
        x, y = frame:GetAbsPos()
        local wC, hC = Station.GetClientSize()
        if x + 890 <= wC and y + 630 <= hC then
            return x + 30, y + 30
        end
    end
    return 40, 40
end

--[[ append an item to parent
    MY.UI.Append(hParent, szName, szType, tArg)
    hParent     -- an Window, Handle or MY.UI object
    szName      -- name of the object inserted
    tArg        -- param like width, height, left, right, etc.
]]
MY.UI.Append = function(hParent, szName, szType, tArg)
    return MY.UI(hParent):append(szName, szType, tArg)
end

MY.Debug("ui plugins inited!\n",nil,0)