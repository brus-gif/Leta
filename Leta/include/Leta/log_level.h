#ifndef LETA_INCLUDE_LETA_LOGLEVEL_H
#define LETA_INCLUDE_LETA_LOGLEVEL_H
#include<../export.h>
#include<../types.h>
namespace Leta {
    class LETA_API LogLevel final
    {
public:
enum class Level:u8
{
    LOG_LV_DEBUG=1,//记录调试细节，变量，执行流程等信息
    LOG_LV_INFO=2,//记录正常运行的信息，eg:连接成功
    LOG_LV_WARN=3,//记录可能存在的问题，警告，但程序能正常运行
    LOG_LV_ERROR=4,//操作失败，有异常，要检查和处理
    LOG_LV_FATAL=5,//严重故障，继续执行会带来损失
    LOG_LV_OFF=6,//关闭日志
};

[[nodiscard]] static std::string_view ToString(Level level)noexcept;
[[nodiscard]] static LogLevel::Level FromString(std::string_view value)noexcept;
    
};

}



#endif 