
#GLOB_RECURSE：从当前 CMakeLists.txt 所在目录递归遍历所有子文件夹；

file(GLOB_RECURSE LETA_SOURCE CONFIGURE_DEPENDS *cpp *.cc *.c)
file(GLOB_RECURSE LETA_HEADERS CONFIGURE_DEPENDS *.h *.hpp)


# 把头文件一起写进去：IDE（CLion、VS）可以把头文件在项目树里展示出来,不会影响编译,CMake编译只看源文件。
# 这里STATIC是创建静态库，创建好的静态库最后会在主CMakeLists文件被链接到最终的动态库上
add_library(Leta STATIC ${LETA_SOURCE} ${LETA_HEADERS})

#给上面的Leta目标创建一个别名Leta::Leta。
# 1.ALIAS别名目标不会生成新的库文件，只是一个名字映射，Leta::Leta和Leta指向完全同一个目标。
add_library(Leta::Leta ALIAS Leta)

redefine_file_macro("${LETA_SOURCES}")

#target_compile_features：给目标设置 C++ 标准特性;PUBLIC cxx_std_20:Leta库本身编译用 C++20;所有链接Leta的下游程序，自动要求 C++20。
target_compile_features(Leta PUBLIC cxx_std_20)

#$<BUILD_INTERFACE:path>:源码树内编译的时候生效${CMAKE_CURRENT_SOURCE_DIR}/include:当前CMakeLists目录下的include文件夹，开发时Leta内部、下游子项目都可以#include"xxx.h"
#PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src：src 目录是Leta内部私有头文件，只有Leta自己编译的时候能搜到;下游链Leta的代码，不能直接include src下面的头文件，做了内部封装隔离。
#它是给目标（pans）的属性列表里挂载一组 include 路径，并打上可见性标记 + 生成器表达式条件
# BUILD_INTERFACE在当前库编译时，指定头文件。如果当前库是导出Letatargets.cmake就不生效，INSTALL_INTERFACE是会将路径加到导出的target.cmake，
# 在别人使用时可以直接include到对应的头文件
target_include_directories(Leta
    PUBLIC 
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src
)

find_package(Threads REQUIRED)
#PUBLIC / PRIVATE / INTERFACE是现代 CMake 最重要的三组可见性：
#PUBLIC：当前目标自己要用，同时依赖这个库的下游目标也会继承（头文件、编译特性、链接库、编译选项）
#PRIVATE：仅Leta库内部编译链接使用，下游不会继承
#INTERFACE：当前目标本身不用，只有链接它的下游目标才会拿到
#pans_options是项目里另一个自定义库目标（通常是INTERFACE库，只放配置不放源码）。
#PUBLIC:Leta自己继承Leta_options 的编译参数，下游链接Leta也自动继承Leta_options 的编译选项，统一整个工程编译规范。
target_link_libraries(Leta PUBLIC Leta_options)

target_link_libraries(Leta PUBLIC Threads::Threads)

if(WIN32)
#WIN32：Windows 平台，私有链接dbghelp.lib微软库，用于栈回溯、符号解析、崩溃dump、backtrace。
# PRIVATE:只是Leta内部崩溃打印栈用，下游不需要感知。
    target_link_libraries(Leta PRIVATE dbghelp)
elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
# Linux：用 pkgconfig 找到libdw（elfutils 的库，用于解析ELF符号、栈回溯，和Windows dbghelp功能对等),目标名PkgConfig::LETA_LIBDW`。
    # target_link_libraries(Leta PRIVATE PkgConfig::LETA_LIBDW)
endif()

# target_link_libraries(Leta PUBILC yaml-cpp::yaml-cpp)
# target_link_libraries(Leta PRIVATE Boost::context)

# add_dependencies(Leta Leta_third_party_dependencies)




#整体含义:只有 GCC / Clang编译器编译Leta库本身的时候,开启-Werror更严格的报警;MSVC不执行这段。
#PRIVATE：这个-Werror只作用于Leta自己的源码，下游项目不会继承 “警告变错误”，下游可以宽松一点，框架库本身严格，业务代码不强制。
target_compile_options(Leta PRIVATE 
$<$<OR:$<CXX_COMPILER_ID:GUN>,$<CXX_COMPILER_ID:Clang>>
    -Werror
>)

#install(TARGETS)：安装Leta库文件，同时把目标信息导出到pansTargets导出集。
#EXPORT pansTargets：把Leta目标的所有属性（头文件路径、链接库、编译特性）打包进导出文件，下游find_package(Leta)加载LetaTargets.cmake就能自动拿到Leta::Leta。
#ARCHIVE：静态库产物（.a/.lib）安装到${CMAKE_INSTALL_LIBDIR}（默认 lib 或者 lib64）
#LIBRARY：动态库 .so/.dll.so（这里Leta是STATIC，兼容写法，改成动态库也不用改install）
#RUNTIME：可执行文件、Windows dll本体，放到bin；静态库场景本条无效，兼容配置。
install(TARGETS Leta
    EXPORT LetaTargets
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}

)
# 把Leta_options这个INTERFACE目标，也一并导出到pansTargets,下游find_package之后，Leta::Leta依赖的Leta_options也一并可用
install(TARGETS Leta_options EXPORT LetaTargets)
# 安装头文件目录：源码树的 `include/` 下所有头文件，复制到安装前缀的 include 目录，对外提供给使用者。
install(DIRECTORY include/ DESTINATION ${CMAKE_INSTALL_INCLUDEDIR} )

