set __FCI_PLUGIN_KUBECTL_FZF_COMMAND "mock_kubectl"

function mock_kubectl
    echo kubectl fzf $argv
end


@echo == Supported commands

set testCases \
    "kubectl get -o yaml pods name -n namespace" \
    "kubectl -n namespace logs pod2" \
    "kubectl describe crd name" \
    "kubectl delete deploy --namespace namespace deploy1" \
    "kubectl port-forward " \
    "kubectl logs " \
    "kubectl logs -f " \
    "kubectl get svc -w svc-name" \
    "kubectl get cm -o yaml "

set expecteds \
    "kubectl fzf pods -n namespace -q name" \
    "kubectl fzf pods -n namespace -q pod2" \
    "kubectl fzf crd -q name" \
    "kubectl fzf deploy -n namespace -q deploy1" \
    "kubectl fzf pods,services" \
    "kubectl fzf pods" \
    "kubectl fzf pods" \
    "kubectl fzf svc -q svc-name" \
    "kubectl fzf cm"

for i in (seq 1 (count $testCases))
    set -l testCase $testCases[$i]
    set -l expected $expecteds[$i]
    set -l args (string split " " $testCase)
    @test "Support commands: $args" (
        echo (fci_plugin_kubectl_fzf $args)
    ) = $expected
end


@echo == Unsupported commands

set testCases \
    "kubectl apply -f " \
    "kubectl get" \
    "kubectl describe svc" \
    "kubectl delete rs" \
    "kubectl port-forward" \
    "kubectl -c sidecar log" \
    "kubectl -n namespace get" \
    "kubectl "

for testCase in $testCases
    set -l args (string split " " $testCase)
    @test "Unsupported commands: $args" (
        fci_plugin_kubectl_fzf $args
    ) $status -ne 0
end
