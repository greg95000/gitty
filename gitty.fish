function gitty

    function clone_repo
        read -l -P "What is your repo address? " repo_address
        read -l -P "What is your repo default branch? [Default : master] " default_branch
        read -l -P "What is your upstream repo? " upstream_repo
        if test $default_branch = ""
            set default_branch "master"
        end
        set directory_name (basename $repo_address .git)
        set directory_path (pwd)"/$directory_name"
        set settings_path $directory_path"/.gitty.settings"
        set upstream_name "upstream"
        git clone $repo_address
        echo "Creation of: "$settings_path
        echo "set -g repo_address \"$repo_address\"" > $settings_path
        echo "set -g default_branch \"$default_branch\"" >> $settings_path
        echo "set -g upstream_repo \"$upstream_repo\"" >> $settings_path
        echo "set -g upstream_name \"$upstream_name\"" >> $settings_path
        echo "set -g current_branch \"$default_branch\"" >> $settings_path
        echo "Moving to the git repo"; cd $directory_path
        git remote add $upstream_name $upstream_repo
        set selected_branch (git branch  --no-color  | grep -E '^\*' | sed 's/\*[^a-z]*//g')
        if test $selected_branch != $default_branch
            git checkout -b $default_branch
            git push --set-upstream origin $default_branch
        end
    end

    function get_variables
        while read -la line
            eval $line
        end < ".gitty.settings"
    end

    function push
        get_variables
        if test $upstream_repo != ""
            git pull -r $upstream_name $default_branch
        end
        git push origin $current_branch
    end

    function switch_branch
        read -l -P "What is your new branch? " new_branch
        set -g current_branch $new_branch
        sed -i "/set -g current_branch \"(.*)\"/c\set -g current_branch \"$new_branch\"" ".gitty.settings"
        for line in (git branch  --no-color  | sed 's/\ *[^a-z/\-_]*//g')
            if test $line = $new_branch
                git checkout $new_branch
                return
            end
        end
        git checkout -b $new_branch
        git push --set-upstream origin $new_branch
    end

    function display_help
        echo "You can use the following commands:"
        echo "--clone, -c: Clone the forked repository and set the upstream"
        echo "--push, -p: Pull rebase the upstream to the initial branch and push if there is no merge to do"
        echo "--switch, -sw: Switch to a branch (create one if the branch does not exist)"
    end

    for option in $argv
        switch "$option"
            case -c --clone
                clone_repo
            case -p --push
                push
            case -h --help
                display_help
            case -sw --switch
                switch_branch
        end
    end
end
