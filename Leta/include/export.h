
//想要打包库文件为windows的dll动态库，要定义了LETA_SHARED_LIBRARY和LETA_BUILDING_LIBRARY宏，想要使用这个动态库就只LETA_SHARED_LIBRARY
#if defined(_WIN32)&&defined(LETA_SHARED_LIBRARY)
#if defined(LETA_BUILDING_LIBRARY)
#define LETA_API __declspec(dllexport)//导出库创建dll和lib
#else
#define LETA_API __declspec(dllimport)//使用dll中开放的函数
#endif

// 在linux环境下打包so动态库只需要定义LETA_SHARED_LIBRARY就可以了
//liunx的动态库符号可见性由 GCC 的编译选项-fvisibility维护：-fvisibility=hidden是所有符号均不可见（除了加API设定为**`__attribute__((visibility("default")))`**）
//而不加-fvisibility=hidden默认是符号visibility = default全都可见的。工业一般用前者

#elif defined(__GNUC__) && defined(LETA_SHARED_LIBRARY)
#define LETA_API __attribute__((vissbility("default")))
#else
#define LETA_API
#endif

#endif