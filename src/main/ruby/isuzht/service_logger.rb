# Набор сервисных методов для логирования из любой точки
#
# @param Возможные комбинации аргументов
#   [String]
#   [String, Exception]
#   [String, Exception, Hash]
#   [String, Symbol]
#   [String, Symbol, Hash]
#   [Fixnum]
#   [Exception]
#   [Exception, Hash]
# Где:
#   String - текст сообщения
#   Fixnum - отладочный код
#   Exception - ошибка
#   Symbol - вызывающий метод (__method__)
#   Hash - хеш с отладочными данными
#
# @examples
#   dbg 'Отладка'
#   dbg 'Отладка', __method__
#   dbg 'Отладка', __method__, {obj_id: obj_id, train_id: train_id}
#
#   def meth
#     raise 'Ошибка'
#   rescue => e
#     err e
#   end
#
#   def meth
#     raise 'Ошибка'
#   rescue => e
#     err "#{ e }. obj_id: #{ obj_id }, train_id: #{ train_id }", e
#   end
#
#   def meth
#     raise 'Ошибка'
#   rescue => e
#     err e, {obj_id: obj_id, train_id: train_id}
#   end
module ::Kernel
  def err *args; log :err, *args; end
  def dbg *args; log :dbg, *args; end
  def inf *args; log :inf, *args; end
  def log type, args_1, args_2 = nil, args_3 = nil
    case args_1
    when String
      mess = args_1
      case args_2
      when Exception then e         = args_2
      when Symbol    then meth      = args_2
      when Hash      then data_hash = args_2
      end
    when Fixnum
      mess = args_1
    when Exception
      e = args_1
      mess = e.to_s
      data_hash = args_2 if args_2.is_a? Hash
    end
    data_hash ||= args_3
    meth ||= begin
      meth_str =
        if e
          e.backtrace.find { |str| str[/^(User::)|(\(eval\))/] }
        else
          caller[1]
        end
      if meth_str
        meth_str.match(/`(.*)'/)[1]
      elsif e.is_a? Java::OrgApacheCayenne::CayenneRuntimeException
        message = e.cause.to_s
        ''
      else
        ''
      end
    end
    clazz =
      if self.is_a? ::Module
        meth = "self_#{meth}"
        name
      else
        self.class.name
      end
    message ||= "#{clazz.gsub('User::', '')}.#{meth}: #{mess || e}"
    message += ". #{data_hash}" if data_hash
    case type
    when :err then LogUtil.logger.error message, e
    when :dbg then LogUtil.logger.debug message, e
    when :inf then LogUtil.logger.info message, e
    end
  end
  private :log
end
