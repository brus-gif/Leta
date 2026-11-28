cmake_minimum_required(VERSION 3.25)

#系统识别当前的系统环境，看其是否是linux环境，如果是
#强制指定编译器为gcc，并将这个配置写到缓存,这里的FILEPATH是文件路径的类型
if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Linux")
    set(CMAKE_C_COMPILER "/usr/bin/gcc" CACHE FILEPATH "C compiler" FORCE)
    set(CMAKE_CXX_COMPILER "/usr/bin/g++" CACHE FILEPATH "C++ compiler" FORCE)
endif()

# CMAKE_CXX_STANDARD 20：目标使用 C++20。
# CMAKE_CXX_STANDARD_REQUIRED ON：编译器不支持 C++20，直接报错，不自动降级。
# CMAKE_CXX_EXTENSIONS ON：开启 GNU 扩展，不是标准 C++。
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS ON)


project(Leta VERSION 0.1.0 LANGUAGES CXX C)


# GNUInstallDirs：生成跨平台安装路径变量，CMAKE_INSTALL_LIBDIR、CMAKE_INSTALL_BINDIR 等，自动区分 lib /lib64。
# MakePackageConfigHelpers：注册两个函数 configure_package_config_file、write_basic_package_version_file。

include(GNUInstallDirs)
include(CMakePackageConfigHelpers)



# 三个开关默认打开，后面会根据这个开关的状态决定是否执行对应的模块
option(LETA_BUILD_EXAMPLE "Build example" ON)
option(LETA_BUILD_TESTS "Build tests" ON)
option(LETA_BUILD_TOOLS "build tools" ON)



# 1. 先区分两类生成器：
# 多配置生成器（Visual Studio、Xcode）：CMAKE_CONFIGURATION_TYPES有值，一次构建可以切换 Debug/Release,不用CMAKE_BUILD_TYPE。
#  单配置生成器（Makefile、Ninja）：CMAKE_CONFIGURATION_TYPES为空，一次构建只能有一种类型，靠CMAKE_BUILD_TYPE控制。
# 2.if(NOT A AND NOT B)：判断当前是单配置生成器，并且用户没有手动指定构建类型，就强制把CMAKE_BUILD_TYPE设为Debug，写入缓存。
# 3.set_property(...)：给CMAKE_BUILD_TYPE这个缓存变量加一个STRINGS属性，值是四个构建类型，作用是让 cmake-gui 里显示成下拉选择框，只能选这四个值；命令行传非法值不会拦截。
# 4.message(STATUS ...)：在配置阶段打印当前的构建类型，方便用户确认。
if(NOT CMAKE_CONFIGURATION_TYPES AND NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Debug CACHE STRING FORCE)
endif()

set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS Debug Release RelWithDebInfo MinSizeRel)
message(STATUS "build type ${CMAKE_BUILD_TYPE}")



# 1.cmake_host_system_information：跨平台查询主机硬件信息，QUERY NUMBER_OF_LOGICAL_CORES表示查询逻辑 CPU 核心数（包含超线程），结果存入CPU_NUMS变量。
# 2.math(EXPR JOBS "...")：CMake 整数数学运算，按 核心数 × 1.5计算线程数（比如 8 核算 12 线程），目的是吃掉 IO 等待的空隙，提升编译速度。
# 3.set(CMAKE_BUILD_PARALLEL_LEVEL ...)：把计算结果赋值给 CMake 内置变量，这个变量会控制 make/ninja 的默认并发任务数，等价于自动加-jN参数。
cmake_host_system_information(RESULT CPU_NUMS QUERY NUMBER_OF_LOGICAL_CORES)
message(STATUS "cpu nums on current server is ${CPU_NUMS}")
math(EXPR JOBS "${CPU_NUMS}+${CPU_NUMS}/2")
set(CMAKE_BUILD_PARALLEL_LEVEL ${JOBS} CACHE STRING " ")
message(STATUS "compiler default work jobs: ${CAMKE_BUILD_PARALLEL_LEVEL}")


# 1.include(文件路径)：读取并原地执行对应 cmake 文件里的所有代码，和把代码直接写在这里效果完全一样，共享当前作用域的所有变量。
# 2. 三个文件分工：
#    - LetaOptions.cmake：全局编译选项、告警等级、sanitizer（内存检测）开关、宏定义。
#    -LetaDependencies.cmake：第三方依赖查找（find_package）、导入第三方库目标。
#    -functions.cmake：封装项目自定义的 CMake 函数，比如统一添加测试、统一创建库的模板函数，减少重复代码。
include(cmake/LetaOptions.cmake)
# include(cmake/LetaDependencies.cmake)
include(cmake/function.cmake)


# 跳转执行对应的主要代码模块

# add_subdirectory(cmake/boost-context)
add_subdirectory(Leta)



# 根据之前那三个开管宏决定是否执行测试代码和工具代码
if(LETA_BUILD_TESTS)
    enable_testing()
    add_subdirectory(test)
endif()
if(LETA_BUILD_TOOLS)

add_subdirectory(tools)
endif()


# 根据GNUInstallDirs提供的CMAKE_INSTALL_LIBDIR拼接处出lib/cmake/Leta的路径
set(LETA_INSTALL_CMAKEDIR "${CMAKE_INSTALL_LIBDIR}/cmake/Leta")



# find_package(Leta) 的工作逻辑是：

# 1. CMake 按标准路径列表挨个搜索，寻找名为 LetaConfig.cmake的文件；
# 2. 找到后，自动在同目录找LetaConfigVersion.cmake，校验版本是否符合要求；
# 3. 版本校验通过，就加载LetaConfig.cmake，进而导入库目标。
configure_package_config_file(
    cmake/LetaConfig.cmake.in
    "${CMAKE_CURRENT_BINARY_DIR}/LetaConfig.cmake"
    INSTALL_DESTINATION "${LETA_INSTALL_CMAKEDIR}"
)
write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/LetaConfigVersion.cmake"
    VERSION "${PROJECT_VERSION}"
    COMPATIBILITY SameMajorVersion
)

# 登记一条安装时复制文件的规则：把 build 里生成的两个包文件，拷贝到系统标准的包搜索目录。
#FILES后面的两个路径指定要拷贝的源文件；DESTINATION "${LETA_INSTALL_CMAKEDIR}"指定拷贝的目标路径
# 系统安装目录（默认/usr/local）的lib/cmake/Leta/下，出现LetaConfig.cmake、LetaConfigVersion.cmake两个文件。
# 如果缺失，就算编译完了库，两个文件只存在于个人的 build 目录里，find_package搜不到，依旧报找不到包的错误。
install(
    FILES
        "${CMAKE_CURRENT_BINARY_DIR}/LetaConfig.cmake"
        "${CMAKE_CURRENT_BINARY_DIR}/LetaConfigVersion.cmake"
    DESTINATION "${LETA_INSTALL_CMAKEDIR}"
)



# 它不是文件，是 CMake 配置阶段内存里的一个目标导出分组。在子目录的 CMakeLists 里会有install(TARGETS Leta EXPORT LetaTargets ...)
# 这行代码的作用是：把这个库目标，放进名为LetaTargets的分组里；分组里记录了Leta库的全部元信息：
# 头文件的安装路径;库文件（.a/.so）的安装路径;这个库依赖的其他库（boost-context、pthread 等）;要求的 C++ 标准、编译选项
# EXPORT LetaTargets是指定要导出的内存分组名;FILE LetaTargets.cmake是导出后生成的文件名;NAMESPACE Leta::给导入目标加命名空间前缀;DESTINATION目标安装路径
#执行后系统安装目录的lib/cmake/Leta/下，会生成LetaTargets.cmake文本文件，里面核心内容是：定义导入目标Leta::Leta；设置它的头文件路径、库文件路径；设置它的依赖库、编译要求
# 有前面的install，使用find_package(Leta)能找到入口、能过版本校验，但最终报错：
#Target"Leta::Leta" not found，链接时找不到库目标，完全无法使用。

install(
    EXPORT LetaTargets
    FILE LetaTargets.cmake
    NAMESPACE Leta::
    DESTINATION "${LETA_INSTALL_CMAKEDIR}"
)