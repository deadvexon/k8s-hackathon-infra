#!/bin/bash
 
kubeadm init
 
# Set up kubectl for ubuntu user
mkdir -p /home/ubuntu/.kube
cp /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
chown ubuntu:ubuntu /home/ubuntu/.kube/config
 
# Install Weave Net CNI
echo "Installing Weave Net..."
sudo -u ubuntu kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml
 
# Wait for node to become Ready
echo "Waiting for node to become Ready..."
until sudo -u ubuntu kubectl get nodes | grep -q ' Ready '; do
    echo "Node not ready yet, waiting..."
    sleep 5
done
 
# Remove control-plane taint
echo "Removing control-plane taint..."
sudo -u ubuntu kubectl taint node $(hostname) node-role.kubernetes.io/control-plane:NoSchedule- || true
 
# Wait for kube-system pods to be ready
echo "Waiting for kube-system pods to be Ready..."
until sudo -u ubuntu kubectl get pods -n kube-system | grep -Ev 'STATUS|Running|Completed' | wc -l | grep -q '^0; do
    echo "Waiting for system pods..."
    sleep 10
done
 
echo "Kubernetes control-plane setup complete!"
echo "Cluster status:"
sudo -u ubuntu kubectl get nodes
sudo -u ubuntu kubectl get pods --all-namespaces

git clone https://github.com/deadvexon/find-your-bias
sleep 20

kubectl apply -f find-your-bias/k8s-specifications
sleep 10

# setting up the runner 
mkdir actions-runner && cd actions-runner
curl -o actions-runner-linux-x64-2.327.1.tar.gz -L https://github.com/actions/runner/releases/download/v2.327.1/actions-runner-linux-x64-2.327.1.tar.gz
echo "d68ac1f500b747d1271d9e52661c408d56cffd226974f68b7dc813e30b9e0575  actions-runner-linux-x64-2.327.1.tar.gz" | shasum -a 256 -c
tar xzf ./actions-runner-linux-x64-2.327.1.tar.gz
./config.sh --url https://github.com/deadvexon/find-your-bias --token $RUNNER_TOKEN
./run.sh
