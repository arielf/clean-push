MB = main
FB = dev

#
# 3-way diffs
#
d diff:
	#
	# check that our $(FB) branch is identical to $(MB)
	#
	git diff origin/$(MB)
	#
	# check that our $(FB) branch is identical to the _remote_ $(MB)
	#
	git diff remotes/origin/$(MB)

#
# sync remotes
#
s sync:
	#
	# Get latest $(MB) from remote
	#
	git checkout $(MB) && git pull -f && git checkout $(FB)
