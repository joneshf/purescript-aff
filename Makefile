.PHONY: ps erl all run test

all: ps erl

erl:
	mkdir -p ebin
	erlc -o ebin/ output/*/*.erl

ps: update
	psc-package sources | xargs purs compile 'src/**/*.purs'

ps_test: update
	psc-package sources | xargs purs compile 'src/**/*.purs' 'test/Test/Main.purs'

ps_watch: update
	while true; do psc-package sources | xargs purs compile 'src/**/*.purs' ; inotifywait -qre close_write .; done

run: ps erl
	erl -pa ebin -noshell -eval '(main@ps:main@c())(unit)' -eval 'init:stop()'

test: ps_test erl
	erl -pa ebin -noshell -eval '(test_main@ps:main())()' -eval 'init:stop()'

update:
	psc-package update
