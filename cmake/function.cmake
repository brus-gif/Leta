# 创建的是一个可以在cmakelists文件中使用的函数
function(redefine_file_macro filelists)
#IN LISTS：固定关键字，代表后面的名字是一个已经存在的列表变量，不是零散参数。
    foreach(source_file IN LISTS filelists)
        if("${source_file}" STREQUAL "")
            continue()
        endif()
        #IS_ABSOLUTE 路径字符串   功能：判断这个路径字符串格式上是不是绝对路径。
        # 模式ABSOLUTE   功能：把输入路径解析成完整绝对路径，消除相对路径、./、../ 带来的歧义，结果存入absolute_path。
        get_filename_component(absolute_path "${source_file}" ABSOLUTE)
        #获取目标路径相对于基准目录的相对路径，结果放到输出变量。file(RELATIVE_PATH 输出变量 基准目录 目标绝对路径)
        file(RELATIVE_PATH relative_path "${PROJECT_SOURCE_DIR}" "${absolute_path}")
        # MATCHES是正则匹配。
            if(IS_ABSOLUTE "${relative_path}" OR relative_path STREQUAL ".." OR relative_path MATCHES "^\\.\\./")
                get_filename_component(relative_path "${source_file} NAME")
            endif()
            #set_source_files_properties(文件列表 PROPERTIES 属性名 属性值)  给源文件本身挂载属性
            # 属性：COMPILE_DEFINITIONS，含义：编译这个文件时，传给预处理器的宏列表。
            # 值：__FILE__=\"${relative_path}\"CMake 展开后传给编译器：-D__FILE__="src/main.cpp"
            # 等价预处理：#define __FILE__ "src/main.cpp"，覆盖编译器内置__FILE__。
        set_source_files_properties("${source_file}" PROPERTIES COMPILE_DEFINITIONS "__FILE__=\"${relative_path}\"")
        endforeach()
    endfunction()

