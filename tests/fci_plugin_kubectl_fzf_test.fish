set -g __FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI mock_kubectl
set -g FISH_COMPLETION_INTERCEPTOR_FZF_CLI mock_fzf

function run_kubectl_test
    __fci_plugin_run_test \
        --plugin-function=fci_plugin_kubectl_fzf \
        $argv
end

function test_fci_plugin_kubectl_fzf
    @echo == Supported commands

    set -l default_expected_fzf_option $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS

    function kubectl_get_pods_fzf_option --inherit-variable default_expected_fzf_option
        argparse "command=" \
            "preview-command=" \
            "log-command=" \
            "query=" \
            -- $argv

        set -l header "Ctrl-l: kubectl logs / Ctrl-d: kubectl describe / Ctrl-r: Reload"
        echo -n "--multi --header=$header --header-lines=1 --preview=$_flag_preview_command "
        if set -q _flag_query
            echo -n "--query=$_flag_query "
        end
        echo "--bind=ctrl-r:reload($_flag_command) --bind=ctrl-l:change-preview($_flag_log_command)+change-preview-window(follow) --bind=ctrl-d:change-preview($_flag_preview_command)+change-preview-window(nofollow) $default_expected_fzf_option"
    end
    function kubectl_default_fzf_option --inherit-variable default_expected_fzf_option
        argparse "command=" \
            "preview-command=" \
            "query=" \
            -- $argv

        echo -n "--multi --header=Ctrl-r: Reload --header-lines=1 --preview=$_flag_preview_command "
        if set -q _flag_query
            echo -n "--query=$_flag_query "
        end
        echo "--bind=ctrl-r:reload($_flag_command) $default_expected_fzf_option"
    end
    function kubectl_multi_namespace_fzf_option --inherit-variable default_expected_fzf_option
        argparse "command=" \
            "preview-command=" \
            "query=" \
            -- $argv

        echo -n "--multi --header=Ctrl-r: Reload --preview=$_flag_preview_command "
        if set -q _flag_query
            echo -n "--query=$_flag_query "
        end
        echo "--bind=ctrl-r:reload($_flag_command) $default_expected_fzf_option"
    end

    # Test cases for pods
    run_kubectl_test \
        --description="get pods with a namespace and an argument" \
        --command "kubectl get -o yaml -n namespace pods name" \
        --mock-fzf-stdout "pod1 1/1\npod2 1/1" \
        --expected-fzf-option \
            (kubectl_get_pods_fzf_option \
                --preview-command "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI describe pods {1} --namespace=namespace" \
                --query "name" \
                --command "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI get pods --namespace=namespace" \
                --log-command "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI logs --follow {1} --namespace=namespace") \
        --expected-stdout "pod1 pod2"
    run_kubectl_test \
        --description="logs without an argument" \
        --command "kubectl -n namespace logs pod2" \
        --mock-fzf-stdout "pod1 1/1" \
        --expected-fzf-option \
            (kubectl_get_pods_fzf_option \
                --preview-command "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI describe pods {1} --namespace=namespace" \
                --query "pod2" \
                --command "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI get pods --namespace=namespace" \
                --log-command "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI logs --follow {1} --namespace=namespace") \
        --expected-stdout "pod1"
    run_kubectl_test \
        --description "logs with an additional option without a namespace nor an argument" \
        --command "kubectl logs -f " \
        --mock-fzf-stdout "pod1 1/1\npod2 1/1" \
        --expected-fzf-option \
            (kubectl_get_pods_fzf_option \
                --preview-command "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI describe pods {1}" \
                --command "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI get pods" \
                --log-command "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI logs --follow {1}") \
        --expected-stdout "pod1 pod2"
    run_kubectl_test \
        --description "kubectl exec" \
        --command "kubectl -n namespace exec " \
        --mock-fzf-stdout "pod1 1/1\npod2 1/1" \
        --expected-fzf-option \
            (kubectl_get_pods_fzf_option \
                --preview-command "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI describe pods {1} --namespace=namespace" \
                --command "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI get pods --namespace=namespace" \
                --log-command "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI logs --follow {1} --namespace=namespace") \
        --expected-stdout "pod1 pod2"

    # Test cases for non Pods
    run_kubectl_test \
        --description "describe and CRD" \
        --command "kubectl describe crd name" \
        --mock-fzf-stdout "crd1 2024\ncrd2 2024" \
        --expected-fzf-option \
            (kubectl_default_fzf_option \
                --preview-command "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI describe crd {1}" \
                --query "name" \
                --command "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI get crd") \
        --expected-stdout "crd1 crd2"
    run_kubectl_test \
        --description "delete" \
        --command "kubectl delete deploy --namespace namespace " \
        --mock-fzf-stdout "deploy1 1/1\ndeploy2 1/1" \
        --expected-fzf-option \
            (kubectl_default_fzf_option \
                --preview-command "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI describe deploy {1} --namespace=namespace" \
                --command "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI get deploy --namespace=namespace") \
        --expected-stdout "deploy1 deploy2"
    run_kubectl_test \
        --description "port-forward" \
        --command "kubectl port-forward " \
        --mock-fzf-stdout "pod/pod1 1/1\nservice/service1 ClusetrIP" \
        --expected-fzf-option \
            (kubectl_multi_namespace_fzf_option \
                --preview-command "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI describe {1}" \
                --command "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI get pods,services --no-headers=true") \
        --expected-stdout "pod/pod1 service/service1"
    run_kubectl_test \
        --description "with an option without an argument" \
        --command "kubectl get svc -w svc-name" \
        --mock-fzf-stdout "service1 ClusterIP\nservice2 ClusterIP" \
        --expected-fzf-option \
            (kubectl_default_fzf_option \
                --preview-command "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI describe svc {1}" \
                --query "svc-name" \
                --command "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI get svc") \
        --expected-stdout "service1 service2"
    run_kubectl_test \
        --description "with an option with an argument" \
        --command "kubectl get cm --output yaml " \
        --mock-fzf-stdout "cm1 1\ncm2 1" \
        --expected-fzf-option \
            (kubectl_default_fzf_option \
                --preview-command "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI describe cm {1}" \
                --command "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI get cm") \
        --expected-stdout "cm1 cm2"
    run_kubectl_test \
        --description "muliple resources" \
        --command "kubectl get ingress,svc " \
        --mock-fzf-stdout "ingress/ingress1 1\nservice/service1 ClusterIP" \
        --expected-fzf-option \
            (kubectl_multi_namespace_fzf_option \
                --preview-command "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI describe {1}" \
                --command "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI get ingress,svc --no-headers=true") \
        --expected-stdout "ingress/ingress1 service/service1"
    run_kubectl_test \
        --description "all" \
        --command "kubectl get all " \
        --mock-fzf-stdout "pod/pod1 1/1\nservice/service2 1/1" \
        --expected-fzf-option \
            (kubectl_multi_namespace_fzf_option \
                --preview-command "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI describe {1}" \
                --command "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI get all --no-headers=true") \
        --expected-stdout "pod/pod1 service/service2"
    run_kubectl_test \
        --description "with already one argument" \
        --command "kubectl edit -n namespace daemonsets " \
        --mock-fzf-stdout "daemon1 1\ndaemon2 1" \
        --expected-fzf-option \
            (kubectl_default_fzf_option \
                --preview-command "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI describe daemonsets {1} --namespace=namespace" \
                --command "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI get daemonsets --namespace=namespace") \
        --expected-stdout "daemon1 daemon2"
    run_kubectl_test \
        --description "view-secret plugin" \
        --command "kubectl view-secret " \
        --mock-fzf-stdout "secret1 1/1\nsecret2 1/1" \
        --expected-fzf-option \
            (kubectl_default_fzf_option \
                --preview-command "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI describe secrets {1}" \
                --command "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI get secrets") \
        --expected-stdout "secret1 secret2"

    @echo == Unsupported kubectl commands
    run_kubectl_test \
        --description "typing a subcommand" \
        --command "kubectl get" \
        --expected-status 0
    run_kubectl_test \
        --description "typing a resource" \
        --command "kubectl describe svc" \
        --expected-status 0
    run_kubectl_test \
        --description "typing a subcommand for port-forward" \
        --command "kubectl port-forward" \
        --expected-status 0
    run_kubectl_test \
        --description "typing a subcommand for log" \
        --command "kubectl -c sidecar log" \
        --expected-status 0
    run_kubectl_test \
        --description "typing a subcommand for get" \
        --command "kubectl -n namespace get" \
        --expected-status 0
    run_kubectl_test \
        --description "apply" \
        --command "kubectl apply " \
        --expected-status 0
    run_kubectl_test \
        --description "no subcommand" \
        --command "kubectl " \
        --expected-status 0

    @echo === Error cases

    # fzf uses stderr for the interactive interrface so the code doesn't capture stderr
    run_kubectl_test \
        --description "fzf was canceled" \
        --command "kubectl get pods a" \
        --mock-fzf-status 130 \
        --expected-status 130
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
