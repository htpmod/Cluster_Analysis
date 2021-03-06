# -*- coding: utf-8 -*-

require "rsruby"
require File.expand_path("../array",__FILE__)

=begin
#################################################
	逸脱度で使うクラスタ数kを求める処理を行うメソッド
	研究用で条件を満たしてもbreakさせていないので、
	実際にその部分を改良する必要あり。
#################################################
=end


@x = []		#元の入力データ(ただし、正規化している)
@s =[]		#逸脱度の処理の方に値を渡すための変数
@km = []	#クラスタの内容をmainに返すために扱う変数
@km2 = []
@k =1		#クラスタ数管理をする変数
@kk=1		#逸脱度の処理の方に渡す@kmの配列を操作する際に必要
@w=1		#rが閾値以下になった時に終了させる場合に、使う。
Max_Cluster_num = 29        #クラスタをいくつまで増やすか


def cal_r(x)
	tim = 0     #タイムスロット管理
    @x = x
	
	#p "============================================="
    v = []      #V(k)を格納
    r_v = []    #R(k)の値を格納
    r = 1		#R(k)の値を閾値と比べるための変数
	
	
	
	loop do
		km =[]		#クラスタリングした結果を入れる配列
		ww =[]		#プロトコル種別毎の最大値ー最小値を入れておく配列
        w = []		#クラスタ分布幅wを入れておく配列
		@km << nil
	

		#¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬
		#R言語の処理xとは別にmatrix型のデータを読み込んでクラスタリングし，その値をkmに返す
        if ARGV[2].nil?
            p "ERROR：第三引数に【通常データ】ファイル名を入力してください。"
            exit
        end
        filename = ARGV[2]
		rr = RSRuby::instance   #R言語使用に必要
        km = rr.eval_R(<<-RCOMMAND)
			a <- read.csv("#{filename}")
			kmeans(a,#{@k})
		 RCOMMAND
		 #¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬
		#print "k = ",@k,"\tkm = ",km,"\n\n"#["cluster"],"\n"		######確認用######
		@km2 << km


		for kk in 0...km["cluster"].size
			kme = []			#@sに渡すための@kmに渡すために調節した配列
			for ii in 0...@x[kk][0].size
				kme << km["cluster"][kk]
			end

			if @km[@k] == nil
				@km[@k] = [kme]	#何も入ってなければnilから変更する
			else
				@km[@k] << kme	#入っているならば値を追加する
			end
		end

		tim_k = Array.new(@k){[]}
		for k in 0...@k
			for x in 0...@x.size
				if km["cluster"][x] == k+1
					tim_k[k] << x		#後で計算するためにどのタイムスロットがクラスタに属するか入れておく
				end
			end
		end
		#print "tim_k\n",tim_k,"\n"		#どのように分けられているかタイムスロットごとに表示######確認用######
		

		prot = @x[0][1].max+1
		anko = Array.new(prot){[]}			#プロトコルごとの最大/最小値を計算までに入れておく配列　ankoの変数の名前は書いていたときにあんこが食べたいと思ったから
		
		#p tim_k[0]

		for ki in 0...tim_k.size					#tim_kのサイズ分つまりクラスタ数分まわす
			for kj in 0...tim_k[ki].size			#クラスタに属する要素の数分まわす
				for i in 0..@x[tim_k[ki][kj]][1].max	#プロトコルの数分まわす
					for n in 0...@x[tim_k[ki][kj]][0].size		#xの要素分まわす
						if @x[tim_k[ki][kj]][1][n] == i
							anko[i] << @x[tim_k[ki][kj]][0][n]
						end
					end
					
				end
				
			end
			for u in 0 ...prot	
				ww << anko[u].max - anko[u].min
			end
			#print "ww = ",ww,"\n\n\n"					######確認用######
			w << (ww.inject(:*)).to_f
			ww=[]							#wwをリセットして次のプロトコルの要素を入れる？
			anko = Array.new(prot){[]}		#ankoを初期化してリセット
		end
    
		#print "\n\t\t冊冊冊冊冊冊冊冊冊冊冊冊冊冊冊冊冊冊冊冊冊冊冊冊冊冊冊冊冊冊冊冊冊冊冊冊冊冊\n"				


        v << w.inject(:+)
        r = v[-1] /v[0]          #v1が０になることによる、0で割ってしまうことを冒すことがある。
        r_v << r

        #print "w = ",w,"\n\n"							######確認用######
        #print  "V(k) = ",v,"\n\n"						######確認用######
        #print "V(1) = ",v[0],"\n\n"					######確認用######
        #print "v[-1] = ",v[-1],"\n"					######確認用######
        #print "R(k) = ",r,"\n"							######確認用######

        if @k	== Max_Cluster_num	#閾値以下にならなかった場合の無限ループを防ぐ		×(閾値で終了させないので、クラスタ数の最大を設定しておく)
            break
        end   
		
		if r < 0.15&&@w==1
			@kk = @k
			@w += 1
		end
		
		@k+=1
    end
    print "\nR(k) = ",r_v,"\n"	#R(k)を入れた配列の出力	
	
	
#################################ファイル出力部分################################
	filename = File.basename(ARGV[1])
	f =open("result/R(k)/R(k)_#{filename}",'w')
		r_v.each_index do |i|
			f.print i+1,"\t",r_v[i],"\n"
		end
	f.close
##############################################################################

	#p @km[@k-1]					#確認用
	#print "return @km = ",@km,"n"	#確認用
	print "\nクラスタ数k = ",@kk,"\n"		#逸脱度で使うクラスタ数を表示
		@s = [@x,@km[@kk]]			#このまま渡して向こうさんで値とプロトコルを仕分ける
	#p @s	#確認用
	return @s,@kk,@km2
end