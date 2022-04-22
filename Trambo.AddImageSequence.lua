script_name="@TRAMBO: Add Image Sequence"
script_description="Add Image Sequence"
script_author="TRAMBO"
script_version="1.0"

include("Trambo.Library.lua")
default_fd = 40
fd = default_fd
loop = 1
x1=0; y1=0; x3=0; y3=0; x4=0; y4=0; xf=0; yf=0 
main_flag = true
bord_flag = false
shad_flag = false
full_flag = false
openimg = "Open Files"
lineB = "Line-based"
loopB = "Loop-based"
cancel = "Cancel"
num_source = "1img"
--PRIMARY GUI
primaryGUI_button_text = "Apply to Text"
primaryGUI_button_fullimg = "Full Images"
primaryGUI_button = {primaryGUI_button_text,primaryGUI_button_fullimg}

--OPEN IMAGES GUI
openImgGUI_button_open = "         Open         "
openImgGUI_button_cancel = "         Cancel         "
openImgGUI_button = {openImgGUI_button_open,openImgGUI_button_cancel}

--textGUI
textGUI_button_frameDur = "Use Chosen Frame Duration"
textGUI_button_numImg = "Use Chosen Number of Images"
textGUI_button_fbfLines = "     Add 1 Image per Line     "
textGUI_button = {textGUI_button_frameDur,textGUI_button_numImg,textGUI_button_fbfLines}

--fullImgGUI
fullImgGUI_button_line = "Line-duration-based"
fullImgGUI_button_loop = "     Loop-based     "
fullImgGUI_button = {fullImgGUI_button_line,fullImgGUI_button_loop}

--MAIN
function main(sub, sel, act)
  frame1_time = aegisub.ms_from_frame(1)
  frame2_time = aegisub.ms_from_frame(2)
  if frame2_time ~= nil and frame1_time ~= nil then
    default_fd = frame2_time - frame1_time
  end
  sel = open_dialog(sub,sel)
  aegisub.set_undo_point(script_name)
  return sel
end

function open_dialog(sub,sel)
  meta, styles = karaskel.collect_head(sub, false)
  local tempsub = {}
  for i, v in ipairs(sub) do
    table.insert(tempsub,v)
  end

  ADD = aegisub.dialog.display
  ADO = aegisub.debug.out
  ADOP = aegisub.dialog.open

  local pathList = {}
  local sizeList = {}
  local pathList_ass = {}
  local main_path = {}
  local bord_path = {}
  local shad_path = {}
  local full_path = {}
  local main_num = 0; local bord_num = 0; local shad_num = 0; local full_num = 0

  primary_choice,primary_res = ADD(get_primaryGUI(),primaryGUI_button)
  if (primary_choice == primaryGUI_button_text) then
    openImg_choice,openImg_res = ADD(get_openImgGUI(),openImgGUI_button)
    main_flag = openImg_res.main; bord_flag = openImg_res.bord; shad_flag = openImg_res.shad; full_flag = openImg_res.full
    local openImgGUI_valid = false
    if main_flag or bord_flag or shad_flag then openImgGUI_valid = true end
    if openImg_choice == openImgGUI_button_open and openImgGUI_valid then
      if main_flag then
        main_path = ADOP("Choose image files for 1img","","","PNG files (*.png)|*.png", true, true)
        if not main_path then 
          ADO("No image chosen for 1img\n")
          main_flag = false 
        else 
          main_num = #main_path 
        end

      end
      if bord_flag then
        bord_path = ADOP("Choose image files for 3img","","","PNG files (*.png)|*.png", true, true)
        if not bord_path then 
          ADO("No image chosen for 3img\n") 
          bord_flag = false
        else 
          bord_num = #bord_path 
        end

      end
      if shad_flag then
        shad_path = ADOP("Choose image files for 4img","","","PNG files (*.png)|*.png", true, true)
        if not shad_path then 
          ADO("No image chosen for 4img\n") 
          shad_flag = false
        else 
          shad_num = #shad_path 
        end
      end
      local textGUI_valid = true
      if main_flag then
        num_source = "1img"
      elseif bord_flag then
        num_source = "3img"
      elseif shad_flag then
        num_source = "4img"
      else
        ADO("No image chosen\n")
        textGUI_valid = false
      end

      if textGUI_valid then 
        text_choice,text_res = ADD(get_textGUI(),textGUI_button)

        x1 = text_res.xmain; y1 = text_res.ymain
        x3 = text_res.xbord; y3 = text_res.ybord
        x4 = text_res.xshad; y4 = text_res.yshad
        xyList = {{x1,y1},{},{x3,x3},{x4,y4}}
        pathList = {main_path,{},bord_path,shad_path}
        numList = {main_num,0,bord_num,shad_num}
        opt={text_res.main,false,text_res.bord,text_res.shad}
        num_source = text_res.numImgSource
        if text_choice == textGUI_button_frameDur then 
          fd = text_res.frameDur
          for si,li in ipairs(sel) do
            local line = sub[li]
            karaskel.preproc_line(sub, meta, styles, line)
            line.actor = line.actor .. " *c" .. tostring(os.time()):match(".....$") .. si .. "*"
            local numLine = math.floor(line.duration/fd)
            local tstart = line.start_time; local tend = line.end_time
            local ldur = line.duration
            local tfin, fin, tfout, fout
            local t1,t2,t3,t4
            local hasFade = false
            local temp = line
            karaskel.preproc_line(sub, meta, styles, temp)
            temp.comment = false
            if line.text:find("\\fade?%(") then 
              hasFade = true
              fin,fout = line.text:match("fade?%((%d+),(%d+)%)")
            end

            local x1,y1,x2,y2,tmove1,tmove2, dx, dy
            local m = 0
            local hasMove = false
            if line.text:find("\\move%(") then
              hasMove = true
              x1,y1,x2,y2,tmove1,tmove2 = line.text:match("\\move%((%d+%.?%d*),(%d+%.?%d*),(%d+%.?%d*),(%d+%.?%d*),(%d+),(%d+)%)")
              x1 = tonumber(x1); 
              y1 = tonumber(y1); 
              x2 = tonumber(x2); 
              y2 = tonumber(y2); 
              tmove1 = tonumber(tmove1)
              tmove2 = tonumber(tmove2)
              dx = (x2-x1)/math.floor((tmove2-tmove1)/fd); 
              dy = (y2-y1)/math.floor((tmove2-tmove1)/fd); 
            end

            for i = numLine,1,-1 do
              temp.start_time = tstart+fd*(i-1)
              if i == numLine then 
                temp.end_time = tend
              else
                temp.end_time = tstart+fd*i
              end

              if hasFade then
                local tdiff = fd*(i-1)
                t1 = -tdiff; t2 = fin - tdiff; t3 = ldur-fout - tdiff; t4 = ldur - tdiff
                local fadeStr = string.format("\\fade(255,0,255,%d,%d,%d,%d)",t1,t2,t3,t4)
                temp.text = line.text:gsub("\\fade?%(.-%)",fadeStr,1)
              end
              if hasMove then
                if fd*i >= tmove1 and fd*i <= tmove2 then m = m + 1 end
                local newx = x2-dx*m;
                local newy = y2-dy*m; 
                local tempx = string.format("%.3f",newx); 
                local tempy = string.format("%.3f",newy); 
                local posStr = "\\pos(" .. tempx .. "," .. tempy .. ")"
                if line.text:find("\\move%(") then  
                  temp.text = temp.text:gsub("\\move%(.-%)",posStr,1)
                elseif line.text:find("\\pos%(") then
                  temp.text = temp.text:gsub("\\pos%(.-%)",posStr,1)
                end
              end


              for j = 1,4,1 do 
                if opt[j] then
                  local n
                  if i % numList[j] == 0 then
                    n = numList[j];
                  else
                    n = i % numList[j];
                  end
                  temp = add_img_to_line(temp,pathList[j][n],xyList[j][1],xyList[j][2],j);
                end
              end
              sub.insert(li+1,temp)

            end

            for j=si,#sel-1,1 do
              sel[j+1] = sel[j+1]+numLine
            end
            if not line.comment then
              line = sub[li]
              line.comment = true
              line.actor = line.actor .. " *p" .. tostring(os.time()):match(".....$") .. si .. "*"
              sub[li] = line
            end
          end
        elseif text_choice == textGUI_button_numImg then 
          local numLine = 0
          if num_source == "1img" then
            numLine = numList[1]; 
          elseif num_source == "3img" then 
            numLine = numList[3];  
          elseif num_source == "4img" then 
            numLine = numList[4]; 
          end
          for si,li in ipairs(sel) do
            local line = sub[li]
            karaskel.preproc_line(sub, meta, styles, line)
            line.actor = line.actor .. " *c" .. tostring(os.time()):match(".....$") .. si .. "*"
            local temp_fd = line.duration/numLine
            local tstart = line.start_time; local tend = line.end_time
            local ldur = line.duration
            local tfin, fin, tfout, fout
            local t1,t2,t3,t4
            local hasFade = false
            local temp = line
            karaskel.preproc_line(sub, meta, styles, temp)
            temp.comment = false
            if line.text:find("\\fade?%(") then 
              hasFade = true
              fin,fout = line.text:match("fade?%((%d+),(%d+)%)")
            end

            local x1,y1,x2,y2,tmove1,tmove2, dx, dy
            local m = 0
            local hasMove = false
            if line.text:find("\\move%(") then
              hasMove = true
              x1,y1,x2,y2,tmove1,tmove2 = line.text:match("\\move%((%d+%.?%d*),(%d+%.?%d*),(%d+%.?%d*),(%d+%.?%d*),(%d+),(%d+)%)")
              x1 = tonumber(x1); 
              y1 = tonumber(y1); 
              x2 = tonumber(x2); 
              y2 = tonumber(y2); 
              tmove1 = tonumber(tmove1)
              tmove2 = tonumber(tmove2)
              dx = (x2-x1)/math.floor((tmove2-tmove1)/fd)
              dy = (y2-y1)/math.floor((tmove2-tmove1)/fd)
            end

            for i = numLine,1,-1 do
              temp.start_time = tstart+temp_fd*(i-1)
              if i == numLine then 
                temp.end_time = tend
              else
                temp.end_time = tstart+temp_fd*i
              end

              if hasFade then
                local tdiff = temp_fd*(i-1)
                t1 = -tdiff; t2 = fin - tdiff; t3 = ldur-fout - tdiff; t4 = ldur - tdiff
                local fadeStr = string.format("\\fade(255,0,255,%d,%d,%d,%d)",t1,t2,t3,t4)
                temp.text = line.text:gsub("\\fade?%(.-%)",fadeStr,1)
              end
              if hasMove then
                if temp_fd*i >= tmove1 and temp_fd*i <= tmove2 then m = m + 1 end
                local newx = x2-dx*m;
                local newy = y2-dy*m; 
                local tempx = string.format("%.3f",newx)
                local tempy = string.format("%.3f",newy)
                local posStr = "\\pos(" .. tempx .. "," .. tempy .. ")"
                if line.text:find("\\move%(") then  
                  temp.text = temp.text:gsub("\\move%(.-%)",posStr,1)
                elseif line.text:find("\\pos%(") then
                  temp.text = temp.text:gsub("\\pos%(.-%)",posStr,1)
                end
              end
              
              for j = 1,4,1 do 
                if opt[j] then 
                  local n = i
                  if numList[j] < numLine then
                    if i % numList[j] == 0 then
                      n = numList[j]; 
                    else
                      n = i % numList[j]; 
                    end
                  end
                  temp = add_img_to_line(temp,pathList[j][n],xyList[j][1],xyList[j][2],j);
                end
              end
              sub.insert(li+1,temp)
            end

            for j=si,#sel-1,1 do
              sel[j+1] = sel[j+1]+numLine
            end
            if not line.comment then
              line = sub[li]
              line.comment = true
              line.actor = line.actor .. " *p" .. tostring(os.time()):match(".....$") .. si .. "*"
              sub[li] = line
            end
          end
        elseif text_choice == textGUI_button_fbfLines then
          for si,li in ipairs(sel) do
            local line = sub[li]
            karaskel.preproc_line(sub, meta, styles, line)
            line.actor = line.actor .. " *c" .. tostring(os.time()):match(".....$") .. si .. "*"
            --local temp = line
            --temp.comment = false

            for j = 1,4,1 do 
              if opt[j] then 
                if si % numList[j] == 0 then
                  n = numList[j];
                else
                  n = si % numList[j];
                end
                line = add_img_to_line(line,pathList[j][n],xyList[j][1],xyList[j][2],j); 
              end
            end
            sub[li] = line
          end
        end
      end
    elseif openImg_choice == openImgGUI_button_open and not openImgGUI_valid then
      ADO("No option chosen")
    elseif openImg_choice == openImgGUI_button_cancel then
      aegisub.cancel()
    end
  elseif (primary_choice == primaryGUI_button_fullimg) then  
    full_path = ADOP("Choose image files","","","PNG files (*.png)|*.png", true, true)
    if not full_path then 
      ADO("No image chosen\n") 
    else 
      full_num = #full_path 
      fullImg_choice,fullImg_res = ADD(get_fullImgGUI(),fullImgGUI_button)
      fd = fullImg_res.frameDur
      loop = fullImg_res.numLoop
      if fullImg_choice == fullImgGUI_button_line then 
        for si,li in ipairs(sel) do
          local line = sub[li]
          karaskel.preproc_line(sub, meta, styles, line)
          line.actor = line.actor .. " *c" .. tostring(os.time()):match(".....$") .. si .. "*"
          local numLine = math.floor(line.duration/fd)
          local tstart = line.start_time; local tend = line.end_time
          local temp = line
          temp.comment = false
          for i = numLine,1,-1 do
            temp.start_time = tstart+fd*(i-1)
            if i == numLine then 
              temp.end_time = tend
            else
              temp.end_time = temp.start_time + fd
            end

            local n
            if i % full_num == 0 then
              n = full_num; 
            else
              n = i % full_num; 
            end

            local w, h = getImgSize(full_path[1])
            temp = add_fimg_to_line(temp,full_path[n],0,0, drawRect(w,h));
            sub.insert(li+1,temp)
          end

          for j=si,#sel-1,1 do
            sel[j+1] = sel[j+1] + numLine
          end
          if not line.comment then
            line = sub[li]
            line.comment = true
            line.actor = line.actor .. " *p" .. tostring(os.time()):match(".....$") .. si .. "*"
            sub[li] = line
          end

        end
      elseif fullImg_choice == fullImgGUI_button_loop then 
        for si,li in ipairs(sel) do
          local line = sub[li]
          karaskel.preproc_line(sub, meta, styles, line)
          line.actor = line.actor .. " *c" .. tostring(os.time()):match(".....$") .. si .. "*"
          local numLine = full_num * loop;
          local tstart = line.start_time; local tend = tstart + fd*numLine
          local temp = line
          temp.comment = false
          for i = numLine,1,-1 do
            temp.start_time = tstart+fd*(i-1)
            temp.end_time = temp.start_time + fd

            local n
            if i % full_num == 0 then
              n = full_num; 
            else
              n = i % full_num; 
            end

            local w, h = getImgSize(full_path[1])
            temp = add_fimg_to_line(temp,full_path[n],0,0, drawRect(w,h)); 
            sub.insert(li+1,temp)
          end

          for j=si,#sel-1,1 do
            sel[j+1] = sel[j+1] + numLine
          end
          if not line.comment then
            line = sub[li]
            line.comment = true
            line.actor = line.actor .. " *p" .. tostring(os.time()):match(".....$") .. si .. "*"
            sub[li] = line
          end
        end
      end
    end
  end
end

function get_primaryGUI()
  local primaryGUI = 
  {
    { class = "label", x = 0, y = 0, width = 2, height = 1, label = "Choose a mode"}
  }
  return primaryGUI
end


function get_openImgGUI()
  local openImgGUI =
  {
    { class = "label", x = 0, y = 0, width = 3, height = 1, label = "Add image sequence to:"},
    { class = "checkbox", x = 0, y = 1, width = 1, height = 1, label = "1img", value = main_flag, name = "main"},
    { class = "checkbox", x = 2, y = 1, width = 1, height = 1, label = "3img", value = bord_flag, name = "bord"},
    { class = "checkbox", x = 4, y = 1, width = 1, height = 1, label = "4img", value = shad_flag, name = "shad"},
  }
  return openImgGUI
end


function get_textGUI()
  local textGUI =
  {
    { class = "label", x = 0, y = 0, width = 1, height = 1, label = "Frame Duration (ms)"},
    { class = "intedit", x = 1, y = 0, width = 1, height = 1, min = 0, max  = 10000, value = fd, name = "frameDur", hint = "Frame duration of source = " .. default_fd},
    { class = "label", x = 2, y = 0, width = 1, height = 1, label = "Use number of images from"},
    { class = "dropdown", x = 3, y = 0, width = 1, height = 1, items = {"1img","3img","4img"}, value = num_source, name = "numImgSource"},
    { class = "checkbox", x = 1, y = 1, width = 1, height = 1, label = "1img", value = main_flag, name = "main"},
    { class = "checkbox", x = 2, y = 1, width = 1, height = 1, label = "3img", value = bord_flag, name = "bord"},
    { class = "checkbox", x = 3, y = 1, width = 1, height = 1, label = "4img", value = shad_flag, name = "shad"},
    { class = "label", x = 0, y = 2, width = 1, height = 1, label = "x offset"},
    { class = "label", x = 0, y = 3, width = 1, height = 1, label = "y offset"},
    { class = "floatedit", x = 1, y = 2, width = 1, height = 1, min = -10000, max  = 10000, value = x1, name = "xmain", hint = ""},
    { class = "floatedit", x = 1, y = 3, width = 1, height = 1, min = -10000, max  = 10000, value = y1, name = "ymain", hint = ""},
    { class = "floatedit", x = 2, y = 2, width = 1, height = 1, min = -10000, max  = 10000, value = x3, name = "xbord", hint = ""},
    { class = "floatedit", x = 2, y = 3, width = 1, height = 1, min = -10000, max  = 10000, value = y3, name = "ybord", hint = ""},
    { class = "floatedit", x = 3, y = 2, width = 1, height = 1, min = -10000, max  = 10000, value = x4, name = "xshad", hint = ""},
    { class = "floatedit", x = 3, y = 3, width = 1, height = 1, min = -10000, max  = 10000, value = y4, name = "yshad", hint = ""}
  }
  return textGUI
end

function get_fullImgGUI()
  local fullImgGUI = 
  {
    { class = "label", x = 0, y = 0, width = 1, height = 1, label = "Frame Duration (ms)"},
    { class = "intedit", x = 1, y = 0, width = 1, height = 1, min = 0, max  = 10000, value = fd, name = "frameDur", hint = "Frame duration of source = " .. default_fd},
    { class = "label", x = 0, y = 1, width = 1, height = 1, label =   "Number of Loops"},
    { class = "intedit", x = 1, y = 1, width = 1, height = 1, min = 0, max  = 10000, value = loop, name = "numLoop", hint = ""},
  }
  return fullImgGUI
end

--send to Aegisub's automation list
aegisub.register_macro(script_name,script_description,main,macro_validation)script_name="@TRAMBO: Add Image Sequence"
