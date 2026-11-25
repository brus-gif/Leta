#ifndef LETA_SRC_LOGGER_BUFFER_H
#define  LETA_SRC_LOGGER_BUFFER_H
#include<algorithm>
#include<array>
#include<streambuf>
#include<cstring>
#include<cstddef>
#include<string_view>
#include<vector>

namespace Leta::detail{

template<std::size_t INLINE_CAP>
class InlineBuffer
{
public:
void append(const char*data,std::size_t size)
{
if(size==0)
return;
if(m_overflow.empty()&&m_size()+size<=INLINE_CAP)
{
std::memcpy(m_inline.data()+m_size,data,size());
m_size+=size;
return;
}
if(m_overflow.empty())
{

    const std::size_t require_capacity=m_size+size;
    m_overflow.reserve(std::max(INLINE_CAP*2,required_capacity));
m_overflow.insert(m_overflow.end(),m_inline.data(),m_inline.data()+m_size);

}
m_overflow.insert(m_overflow.end(),data,data+size);

m_size=m_overflow.size();

}

void append(std::string_view value)
{

    append(value.data(),value.size());
}

void append(char value)
{
append(&value,1);

}

[[nodiscard]] const char*data()const noexcept
{
return m_overflow.empty()?m_inline.data():m_overflow.data();

}

[[nodiscard]] std::size_t size()const noexcept
{
return m_size;
}
[[nodiscard]] std::string_view view()const noexcept
{
    return {data(),size()};
} // noexcept



private:
//日志量小用栈，实在太大用堆开辟（堆上内存频繁申请可能申请失败）
std::array<char,INLINE_CAP>m_inline{};//栈上固定缓冲区
std::vector<char>m_overflow;//堆上可动态开辟空间的缓冲区
std::size_t m_size=0;

};

//继承streambuf来支持流式输入，<<,兼容ostream
template<std::size_t INLINE_CAP>
class SmallStreamBuffer final :public std::streambuf
{
public:
explict SmallStreamBuffer(InlineBuffer<INLINE_CAP>&buffer)noexcept
:m_buffer(buffer)
{}

protected:
std::streamsize xsputn(const char* data,std::streamsize size)override
{
if(size<=0)
return 0;
m_buffer.append(data,std::static_cast<std::size_t>size);
return size;
}
int_type overflow(int_type character)override
{
if(traits_type::eq_int_type(character,traits_type::eof()))
{return traits_type::not_eof(character);}
m_buffer.append(traits_type::to_char_type(character));
return character;

}


private:
InlineBuffer<INLINE_CAP>m_buffer;
};







}











#endif