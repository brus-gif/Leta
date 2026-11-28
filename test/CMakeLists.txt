# 1.file(GLOB)：文件 glob 扫描，匹配通配符，收集符合后缀的文件路径，存入变量LETA_TEST_SOURCES
# 2.CONFIGURATION_DEPENDS：非常关键,普通file(GLOB)的坑：新增/删除测试cpp文件时,CMake不会自动重新执行glob,需要手动删缓存重configure。
# 加上CONFIGURE_DEPENDS之后，CMake 会监控这批文件；文件列表发生变化，自动触发重新configure，不用手动清缓存。
# 3. 扫描范围：当前CMakeLists所在目录${CMAKE_CURRENT_SOURCE_DIR}下，后缀*.cpp *.cc *.cxx。
file(GLOB LETA_TEST_SOURCES CONFIGURE_DEPENDS
    "${CMAKE_CURRENT_SOURCE_DIR}/*.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/*.cc"
    "${CMAKE_CURRENT_SOURCE_DIR}/*.cxx"
)

# 对收集到的文件路径列表做排序（SORT表示升序）。
# 作用：让遍历顺序稳定，跨机器、跨操作系统，测试目标生成顺序一致，避免 CMake 输出顺序随机带来的观感差异
list(SORT LETA_TEST_SOURCES)
# 配置文件宏，让文件宏得到的文件路径都是相对路径而不是绝对路径
redefine_file_macro("$(LETA_TEST_SOURCES)")


find_package(Threads REQUIRED)

# 这个是赋值操作，旨在将可执行文件的输出路径赋值给LETA_TEST_OUTPUT_DIRRCTORY
set(LETA_TEST_OUTPUT_DIRRCTORY "${PROJECT_SOURCE_DIR}/bin/tests")

foreach(TEST_SOURCE IN LISTS LETA_TEST_SOURCES)
# NAME_WE是可以提取文件名字主干，除去.cpp等后缀
    get_filename_component(TEST_NAME "${TEST_SOURCE}" NAME_WE)
    if(TARGET"${TEST_NAME}")
    message(FATAL_ERROR "Cannot create test target '${TEST_NAME}': a target with that name already exists")
endif()
add_executable("${TEST_NAME}" "${TEST_SOURCE}")

target_link_libraries("${TEST_NAME}" PRIVATE Threads::Threads)
# target_link_libraries("${TEST_NAME}" PRIVATE Leta Threads::Threads)

# 1.set_target_properties()：给目标附加属性。属性是 CMake 目标的元数据，控制构建、输出、链接行为。
# 2.PROPERTIES关键字：后面跟着一组属性名 属性值对。
# 3.RUNTIME_OUTPUT_DIRECTORY：目标属性。语义：运行时产物（Windows 下.exe、.dll；Linux下ELF可执行程序）的输出目录。
# 配套另外两个同类属性，区分产物类型：
#    - ARCHIVE_OUTPUT_DIRECTORY：静态库.a/.lib 和 - LIBRARY_OUTPUT_DIRECTORY：动态库.so
# 4. 生效规则：
# CMake 生成器分为两大类：
# - 单配置生成器：Unix Makefiles、Ninja。这类生成器在 configure 阶段就锁定唯一构建类型（-DCMAKE_BUILD_TYPE=Debug/Release），构建目录里只有一套产物。
# 单配置生成器读取、生效这个 RUNTIME_OUTPUT_DIRECTORY 属性。编译出来的 exe 直接放到这个路径，不会追加子文件夹。
#- 多配置生成器：Visual Studio、Xcode。这类生成器一次 configure，同时支持 Debug、Release、RelWithDebInfo、MinSizeRel，构建目录里存放多套产物
# 多配置生成器直接忽略 RUNTIME_OUTPUT_DIRECTORY 这个属性，完全不读取，它只认带 CONFIG 后缀的版本。

set_target_properties("${TEST_NAME}" PROPERTIES
RUNTIME_OUTPUT_DIRECTORY "${LETA_TEST_OUTPUT_DIRECTORY}"
)
# 上面的是对单配置生成器的操作，set_target_properties在多配置生成器下，RUNTIME_OUTPUT_DIRECTORY不读取。
# 所以这里额外对多配置生成器进行操作CMAKE_CONFIGURATION_TYPES在单配置生成器（Makefile/Ninja）时：这个变量是空列表，循环一次都不执行。
#在多配置生成器（VS/Xcode）时：这个变量的值是Debug;Release;RelWithDebInfo;MinSizeRel，代表当前生成器支持的所有构建配置。
# CMake 的目标属性RUNTIME_OUTPUT_DIRECTORY_<CONFIG> 有强制语法要求：配置后缀必须是全大写。所以这里的string将输入转大写写到了CONFIG_UPPER中
foreach(CONFIG IN LISTS CMAKE_CONFIGGURATION_TYPES)
    string(TOUPPER "${CONFIG}" CONFIG_UPPER)
    set_target_properties("${TEST_NAME}" PROPERTIES
        "RUNTIME_OUTPUT_DIRECTORY_${CONFIG_UPPER}" "${LETA_TEST_OUTPUT_DIRECTORY}"
    )
endforeach()

#向 CTest 的全局测试注册表注册一条测试用例。它只是做注册登记，既不会编译程序，也不会自动运行程序。编译靠cmake --build，执行测试靠ctest命令。
# 要让 CTest 能识别到所有注册的用例，顶层 CMakeLists.txt 必须写 enable_testing()，否则就算注册了,ctest也找不到任何测试。
# NAME "${TEST_NAME}"将目标名作为唯一性标识;
# COMMAND "${TEST_NAME}"是由add_executable创建的目标名，CMake会读取该目标的LOCATION属性:LOCATION的来源就是目标的RUNTIME_OUTPUT_DIRECTORY（通用）
# 或者RUNTIME_OUTPUT_DIRECTORY_<CONFIG>（分配置），编译输出的可执行文件固定放在该目录。
add_test(NAME "${TEST_NAME}" COMMAND "${TEST_NAME}")
endforeach()
# add_subdirectory(inner_tests)