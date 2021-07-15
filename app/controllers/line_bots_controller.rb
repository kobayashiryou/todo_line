class LineBotsController < ApplicationController
  require "line/bot"

  protect_from_forgery with: :null_session

  def callback
    body = request.body.read

    # LINE以外からリクエストが来た場合 Error を返す
    signature = request.env["HTTP_X_LINE_SIGNATURE"]
    unless client.validate_signature(body, signature)
      head :bad_request and return
    end

    # LINEで送られてきたメッセージを適切な形式に変形
    events = client.parse_events_from(body)

    events.each do |event|
      user_id = event["source"]["userId"]
      user = User.find_by( uid: user_id) || User.create(uid: user_id)
      # LINE からテキストが送信された場合
      if (event.type === Line::Bot::Event::MessageType::Text)
        # LINE からテキストが送信されたときの処理を記述する
        message = event["message"]["text"]
        text =
          case message
          when "一覧"
            todos = user.todos

            #indexキーをつけて、.joinメソッドで長い文字列にする。
            #("\n")をつけると文字列を改行してくれる
            todos.map.with_index(1) { |todo, index| "#{index}: #{todo.title}" }.join("\n")
          when /完了+\d/ #//はリテラル文字列で、\はメタ文字列、\dは１０進数を表す、つまり、完了１とかの文字を読み取る
            index = message.gsub(/完了*/, "").strip.to_i
            #受け取った文字が完了１（１０進数）ならば、そのmessageからgsubメソッドにより、完了の文字を削除して、"""で空白を入れる
            #空白をstripメソッドで空白を除き、残った数字を.to_iメソッドで文字列から数字にする。
            todos = user.todos.to_a
            #配列をArrayに変換してtodosに入れる
            todo = todos.find.with_index(1) {|_todo, _index| index == _index}
            #１からの_indexが付されたそれぞれのtodo(_todo)の_indexがindexと合致するものを探す
            todo.destroy!
            "Todo:#{index}が完了しました"
          else
            user.todos.create!(title: message)
            "Todo:[#{message}]の登録が完了しました"
          end

        reply_message = {
          type: "text",
          text: text
        }

        client.reply_message(event["replyToken"], reply_message)
      end
    end

    # LINE の webhook API との連携をするために status code 200 を返す
    render json: { status: :ok }
  end

  private

    def client
      @client ||= Line::Bot::Client.new do |config|
        config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
        config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
      end
    end
end