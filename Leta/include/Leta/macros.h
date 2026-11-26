#ifndef LETA_MACROS_H
#define LETA_MACROS_H
#include<cassert>
// #include<Leta/logger/log.h>
// #include<Leta/utils/system_utils.h>


//#会将这个传入的预处理记号转换成字符面量
//这里,在debug时,如果ASSERT声明错误,会执行日志打印和assert,并abort退出.而在release,有NDEBUG宏,所以assert都是空指令,只执行日志打印
#define LETA_ASSERT(x)\
if(!(x)) [[unlikely]]\
{ \
LETA_LOG_FATAL(PANS_LOG_ROOT())<<"Assert failed:"<<#x<< "\nStacktrace"<<Leta::GetBacktrace();\
assert(x);\
}\
else{}

//增加一个info,也就是w的额外说明的打印
#define LETA_ASSERT2(x ,w)\
if(!(x)) [[unlikely]]\
{\
LETA_LOG_FATAL(LETA_LOG_ROOT())<<"Assert"<<#x<<"failed.["<<w<<"].\nStacktrace:\n"<<pans::GetBacktrace();\
assert(x);\
}\
else{}

#define ASSERT_RETVAL(x,val)\
do{\
if(x)[[likely]] break;\
LETA_ASSERT(x);\
return val;\
}while(0)

#define ASSERT_RETVAL2(x,val,info)\
do{\
if(x)[[likely]] break;\
Leta_ASSERT2(x,info);\
return val;\
}while(0)

#define ASSERT_RETNONE(x)\
do{
if(x)[[likely]] break;\
Leta_ASSERT(x);\
return;\
}while(0)

#define ASSERT_NOEFFECT(x)\
do{\
if(x)[[likely]] break;\
LETA_ASSERT(x);\
}while(0)

#define ASSERT_NOEFFECT2(x,info)\
do{
if(x)[[likely]] break;\
LETA_ASSERT2(x,info);\
}while(0)

#define ASSERT_CONTINUE(x)\
if(!(x))[[unlikely]]\
{LETA_ASSERT(s);\
continue;\
}else{}

#define ASSERT_CONTINUE2(x,info)\
if(!(x))[[unlikely]]\
{LETA_ASSERT2(x,info);\
    continue;\
}else{}

#define ASSERT_BREAK(x)\
if(!(x))[[unlikely]]\
{LETA_ASSERT(x);\
break;\
}else{}

#define ASSERT_BREAK2(x,info)\
if(!(x))[[unlikely]\
{LETA_ASSERT2(x,info);\
break;\
}else{}

#endif
