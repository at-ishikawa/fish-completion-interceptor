function test_fci_plugin_kubectl_fzf
    set -g __FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI mock_kubectl
    set -g FISH_COMPLETION_INTERCEPTOR_FZF_CLI mock_fzf

    function run_kubectl_test \
        --argument-names test_description \
        commandline_arg \
        expected_status \
        expected_stdout \
        expected_stderr
        set -l commandline_args (string split " " $commandline_arg)

        set temp_file (mktemp)
        set -l actual_stdout (fci_plugin_kubectl_fzf $commandline_args 2>$temp_file)
        set -l actual_status $status
        set -l actual_stderr (cat $temp_file)
        rm $temp_file

        @echo "$test_description: $commandline_args"
        # @echo "expected: $expected_stdout, actual: $actual_stdout"
        @test status $actual_status -eq $expected_status
        @test stdout "$actual_stdout" = "$expected_stdout"
        @test stderr "$actual_stderr" = "$expected_stderr"
    end

    @echo == Supported commands

    set -l successful_command "kubectl get -o yaml -n namespace pods name"

    set -l test_cases \
        # Pods
        $successful_command \
        "kubectl -n namespace logs pod2" \
        "kubectl logs -f " \
        "kubectl -n namespace exec " \
        # Non Pods
        "kubectl describe crd name" \
        "kubectl delete deploy --namespace namespace " \
        "kubectl port-forward " \
        "kubectl get svc -w svc-name" \
        "kubectl get cm --output yaml " \
        "kubectl get ingress,svc " \
        "kubectl get all " \
        "kubectl edit -n namespace daemonsets " \
        "kubectl view-secret "
    set -l mock_kubectl_results \
        # Pods
        "NAME READY\npod1 1/1\npod2 1/1" \
        "NAME READY\npod1 1/1" \
        "NAME READY\npod1 1/1\npod2 1/1" \
        "NAME READY\npod1 1/1\npod2 1/1" \
        # Non Pods
        "NAME READY\npod1 1/1\npod2 1/1" \
        "NAME READY\npod1 1/1\npod2 1/1" \
        "NAME READY\npod1 1/1" \
        "NAME READY\npod1 1/1\npod2 1/1" \
        "NAME READY\npod1 1/1\npod2 1/1" \
        "NAME READY\npod1 1/1\npod2 1/1" \
        "NAME READY\npod1 1/1\npod2 1/1" \
        "NAME READY\npod1 1/1\npod2 1/1" \
        "NAME READY\npod1 1/1\npod2 1/1" \
        "NAME READY\nsecret1 1/1\nsecret2 1/1"

    set -l default_expected_fzf_option $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS

    set -l mock_fzf_results \
        # Pods
        "pod1 1/1\npod2 1/1" \
        "pod1 1/1" \
        "pod1 1/1\npod2 1/1" \
        "pod1 1/1\npod2 1/1" \
        # Non Pods
        "pod1 1/1\npod2 1/1" \
        "pod1 1/1\npod2 1/1" \
        "pod1 1/1" \
        "pod1 1/1\npod2 1/1" \
        "pod1 1/1\npod2 1/1" \
        "pod1 1/1\npod2 1/1" \
        "pod1 1/1\npod2 1/1" \
        "pod1 1/1\npod2 1/1" \
        "pod1 1/1\npod2 1/1" \
        "secret1 1/1\nsecret2 1/1"

    function kubectl_describe -a resource
        argparse "namespace=?" -- $argv
        if [ "$_flag_namespace" = "" ]
            echo "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI describe $resource {1}"
        else
            echo "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI describe $resource {1} --namespace=$_flag_namespace"
        end
    end

    set -l pod_fzf_option_format "--multi --header=Ctrl-l: kubectl logs / Ctrl-d: kubectl describe / Ctrl-r: Reload --header-lines=1 --preview=%s %s--bind=ctrl-r:reload(%s) --bind=ctrl-l:change-preview(%s)+change-preview-window(follow) --bind=ctrl-d:change-preview(%s)+change-preview-window(nofollow)"
    set -l default_fzf_option_format "--multi --header=Ctrl-r: Reload --header-lines=1 --preview=%s %s--bind=ctrl-r:reload(%s)"
    set -l multi_namespace_fzf_option_format "--multi --header=Ctrl-r: Reload --preview=%s %s--bind=ctrl-r:reload(%s)"
    set -l expected_fzf_options \
        # Pods
        (printf $pod_fzf_option_format \
            (kubectl_describe pods --namespace=namespace) \
            "--query=name " \
            "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI get pods --namespace=namespace" \
            "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI logs --follow {1} --namespace=namespace" \
            (kubectl_describe pods --namespace=namespace)) \
        (printf $pod_fzf_option_format \
            (kubectl_describe pods --namespace=namespace) \
            "--query=pod2 " \
            "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI get pods --namespace=namespace" \
            "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI logs --follow {1} --namespace=namespace" \
            (kubectl_describe pods --namespace=namespace)) \
        (printf $pod_fzf_option_format \
            (kubectl_describe pods) \
            "" \
            "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI get pods" \
            "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI logs --follow {1}" \
            (kubectl_describe pods)) \
        (printf $pod_fzf_option_format \
            (kubectl_describe pods --namespace=namespace) \
            "" \
            "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI get pods --namespace=namespace" \
            "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI logs --follow {1} --namespace=namespace" \
            (kubectl_describe pods --namespace=namespace)) \
        # Non Pods
        (printf $default_fzf_option_format \
            (kubectl_describe crd) \
            "--query=name " \
            "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI get crd") \
        (printf $default_fzf_option_format \
            (kubectl_describe deploy --namespace=namespace) \
            "" \
            "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI get deploy --namespace=namespace") \
        (printf $multi_namespace_fzf_option_format \
            "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI describe {1}" \
            "" \
            "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI get pods,services --no-headers=true") \
        (printf $default_fzf_option_format \
            (kubectl_describe svc) \
            "--query=svc-name " \
            "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI get svc") \
        (printf $default_fzf_option_format \
            (kubectl_describe cm) \
            "" \
            "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI get cm") \
        (printf $multi_namespace_fzf_option_format \
            "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI describe {1}" \
            "" \
            "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI get ingress,svc --no-headers=true") \
        (printf $multi_namespace_fzf_option_format \
            "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI describe {1}" \
            "" \
            "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI get all --no-headers=true") \
        (printf $default_fzf_option_format \
            "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI describe daemonsets {1} --namespace=namespace" \
            "" \
            "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI get daemonsets --namespace=namespace") \
        (printf $default_fzf_option_format \
            "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI describe secrets {1}" \
            "" \
            "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI get secrets")

    set -l expected_stdouts \
        # Pods
        "pod1\npod2" \
        pod1 \
        "pod1\npod2" \
        "pod1\npod2" \
        # Non Pods
        "pod1\npod2" \
        "pod1\npod2" \
        pod1 \
        "pod1\npod2" \
        "pod1\npod2" \
        "pod1\npod2" \
        "pod1\npod2" \
        "pod1\npod2" \
        "pod1\npod2" \
        "secret1\nsecret2"

    for i in (seq 1 (count $test_cases))
        set -l test_case $test_cases[$i]

        set expected_fzf_option "$expected_fzf_options[$i] $default_expected_fzf_option"
        set mock_fzf_result $mock_fzf_results[$i]
        function mock_fzf \
            --inherit-variable expected_fzf_option \
            --inherit-variable mock_fzf_result

            if [ "$expected_fzf_option" != "$argv" ]
                echo "fzf argv diff: $(diff (echo $argv | string split ' ' | psub) (echo $expected_fzf_option | string split ' ' | psub))" >&2
                # echo "fzf argv: (expected: $expected_fzf_option, actual: $argv)" >&2
                return 255
            end
            echo -e "$mock_fzf_result"
            return 0
        end

        set -l expected_stdout (echo -e "$expected_stdouts[$i]")
        run_kubectl_test "Support commands" $test_case 0 "$expected_stdout" ""
    end


    @echo == Unsupported kubectl commands

    set test_cases \
        "kubectl apply -f " \
        "kubectl get" \
        "kubectl describe svc" \
        "kubectl delete rs" \
        "kubectl port-forward" \
        "kubectl -c sidecar log" \
        "kubectl -n namespace get" \
        "kubectl "

    for test_case in $test_cases
        run_kubectl_test "Unsupported kubectl commands" "$test_case" 0 "" ""
    end

    @echo === fzf errors

    function mock_kubectl
        echo "NAME READY"
        echo "pod   1/1"
    end

    function mock_fzf
        return 130
    end

    # fzf uses stderr for the interactive interrface so the code doesn't capture stderr
    run_kubectl_test "Error when fzf was canceled" $successful_command 130 "" ""
end

function test_fci_plugin_kubectl_fzf_namespace_mode
    function run_namespace_mode \
        --argument-names args \
        expected_status \
        expected_stdout

        set -l actual_stdout (__fci_plugin_kubectl_fzf_namespace_mode "$args")
        set -l actual_status $status

        @echo "Enable namespace mode without a fzf query: $args[$i]"
        @test status $actual_status -eq $expected_status
        @test stdout "$actual_stdout" = "$expected_stdout"
    end

    @echo == __fci_plugin_kubectl_fzf_namespace_mode
    set -l args \
        "kubectl get pods -n" \
        "kubectl get pods -n=" \
        "kubectl get pods --namespace" \
        "kubectl get pods --namespace=" \
        "kubectl get pods -n " \
        "kubectl get pods --namespace "
    for i in (seq 1 (count $args))
        @echo "Enable namespace mode without a fzf query: $args[$i]"
        run_namespace_mode "$args[$i]" 0 ""
    end

    set -l namespace_arg na
    set -l args \
        "kubectl get pods -n $namespace_arg" \
        "kubectl get pods --namespace $namespace_arg" \
        "kubectl get pods -n=$namespace_arg" \
        "kubectl get pods --namespace=$namespace_arg"
    for i in (seq 1 (count $args))
        @echo "Enable namespace mode with a fzf query: $args[$i]"
        run_namespace_mode "$args[$i]" 0 "$namespace_arg"
    end

    set -l args \
        "kubectl get pods -n namespace " \
        "kubectl get pods --namespace namespace po" \
        "kubectl get pods pod-name" \
        "kubectl get pods name"
    for i in (seq 1 (count $args))
        @echo "Not enable namespace mode: $args[$i]"
        run_namespace_mode "$args[$i]" 1 ""
    end
end

test_fci_plugin_kubectl_fzf
test_fci_plugin_kubectl_fzf_namespace_mode
