# 载体目标，不生成任何的库文件，用来批量传递编译选项，连接选项，宏定义，头文件路径
#PRIVATE选项：只给当前目标自己用，不会传递给链接它的其他目标
# PUBLIC：自己用 + 传递给所有链接我的目标
# INTERFACE：自己不用，只传递给所有链接我的目标
# 因为 Leta_options是一个INTERFACE类型的库，它本身不编译、不生成任何实际的库文件，它存在的唯一意义就是批量传递选项。
# - 它自己没有源码，不需要编译、链接，所以 `PRIVATE` 毫无意义；
# - 用 `INTERFACE` 就是实现：任何目标只要链接了 Leta_options，就会自动继承这里所有的编译选项和链接选项。
add_library(Leta_options INTERFACE)

# - 最外层：条件成立才应用后面的选项
# - 条件:$<OR:A,B>->A 或 B 任意一个成立就生效
# - $<CXX_COMPILER_ID:GNU>：判断 C++ 编译器是 GCC
# - $<CXX_COMPILER_ID:Clang>：判断 C++ 编译器是 Clang
target_compile_options(Leta_options INTERFACE
    $<$<OR:$<CXX_COMPILER_ID:GUN>,$<CXX_COMPILER_ID:Clang>>:
    -Wall
    -Wextra
    -Wpedantic
    -fno-strict-aliasing
    -Wno-builtin-macro-redefined
>
    )

# 同时满足Linux 系统和GCC/Clang 编译器两个条件，才加选项；Windows/macOS 自动跳过。
#选项-fPIC本质
# - 全称：Position Independent Code，位置无关代码。
# - 作用：编译生成的机器码不依赖具体的内存加载地址，同一个库可以被多个进程共享映射到不同的虚拟地址空间。
# - 为什么加：编译动态库（.so）必须加这个选项；静态库如果后续要被链接进动态库，也需要加
target_compile_options(Leta_options INTERFACE
    $<$<AND:$<PLATFORM_ID:Linux>,$<or:$<CXX_COMPILER_ID:GUN>,$<CXX_COMPILER_ID:Clang>>>:
    -fpic
>
)

#-rdynamic本质
# - 作用：链接时，把程序的所有符号（函数名、变量名）都加入到动态符号表中。
# - 为什么加：用来支持栈回溯（backtrace）。程序崩溃打印调用栈时，需要从符号表解析函数名；不加这个选项，backtrace 只能拿到地址，看不到函数名，调试崩溃问题非常困难。
target_link_options(Leta_options INTERFACE
    $<$<AND:$<PLATFORM_ID:Linux>,$<OR:$<CXX_COMPILER_ID:GUN>,$<CXX_COMPILER_ID:Clang>>>:
    -rdynamic
>
)

# $<CONFIG:Debug>：只有当前构建类型是 Debug 时，才生效。
# 这是在进行宏定义LETA_DEBUG
# - 作用：Debug 模式下自动定义LETA_DEBUG这个宏。
# - 用途：代码里可以写#ifdef LETA_DEBUG ... #endif，把调试日志、断言、校验逻辑只放在 Debug 版里，Release 版自动剔除。
target_compile_definitions(Leta_options INTERFACE
    $<$<CONFIG:Debug>:LETA_DEBUG>
)

#-o0 关闭所有代码优化
#-g3生成最高级别的调试信息
#-ggdb生成 GDB 专用格式的调试信息
target_compile_options(Leta_options INTERFACE
    $<$<CONFIG:Debug>:-O0>
    $<$<CONFIG:Debug>:-g3>
    $<$<CONFIG:Debug>:-ggdb>

    )

#两个构建类型的定位
#-Release：正式发布版，追求性能，不带调试符号。
#-RelWithDebInfo:带调试信息的发布版，优化级别和 Release 一致，但是保留调试符号，用于线上环境故障定位。
target_compile_options(Leta_options INTERFACE
    $<$<CONFIG:Release>:-DNDEBUG>
    $<$<CONFG:Release>:-O2>
    $<$<CONFIG:Release>:-fno-omit-frame-pointer>

    $<$<CONFIG:RelWithDebInfo>:-DNDEBUG>
    $<$<CONFIG:RelWithDebInfo>:-O2>
    $<$<CONFIG:RelWithDebInfo>:-g>
    $<$<CONFIG:RelWithDebInfo>:-fno-omit-frame-pointer>
    )

#option(ENABLE_COVERAGE ... OFF)：定义一个布尔开关，默认关闭。
# - 开启方式:cmake 时传 -DENABLE_COVERAGE=ON。
# - 仅在 Debug 模式下生效：优化会合并代码、消除分支，导致覆盖率统计不准。
# 2.--coverage 选项本质
# - 作用：编译时在代码里插桩，程序运行后会生成覆盖率数据文件（.gcno/.gcda）。
# - 为什么编译和链接都要加：编译时插桩，链接时要链接覆盖率运行时库（libgcov），两边都加才能正常工作。
# - 用途：配合gcov/lcov 工具，可以统计单元测试覆盖了多少行代码、多少分支，用来衡量测试完备度。
# option(ENABLE_COVERAGE "enable code coverage instrumentation" OFF)
if(ENABLE_COVERAGE)
    target_compile_options(Leta_options INTERFACE
    $<$<CONFIG:Debug>:--coverage>
    
    )
    target_compile_options(
        $<$<CONFIG:Debug>:--coverage>
    )
endif()


# target_compile_options(<目标名> <作用域> <选项1> <选项2> ...)
# - 作用：给指定目标的编译阶段添加编译器参数。
# - 生效时机：每个源文件编译成 .o的时候，编译器会带上这些参数。
# add_compile_options- 全局写法会给项目里所有目标都加上选项，无法精细化控制;目标级写法只作用于指定目标，再通过INTERFACE传递给依赖它的目标，按需生效，不会污染第三方库、测试代码等不需要的模块；

#target_link_options(<目标名> <作用域> <选项1> <选项2> ...) 
# -作用：给指定目标的链接阶段添加链接器参数。
# -生效时机：所有.o文件、库文件拼接成最终产物的时候，链接器会带上这些参数。
# 比如:-rdynamic作用：告诉链接器，把所有全局符号都加入动态符号表；
#--coverage(链接时)作用：告诉链接器，链接覆盖率运行时库 `libgcov`；

