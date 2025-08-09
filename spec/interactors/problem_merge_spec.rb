describe ProblemMerge do
  let(:problem) { Fabricate(:problem_with_notices) }
  let(:problem_1) { Fabricate(:problem_with_notices) }

  describe "#initialize" do
    it 'extract first problem like merged_problem' do
      problem_merge = ProblemMerge.new(problem, problem, problem_1)
      expect(problem_merge.merged_problem).to eql problem
    end
    it 'extract other problem like child_problems' do
      problem_merge = ProblemMerge.new(problem, problem, problem_1)
      expect(problem_merge.child_problems).to eql [problem_1]
    end
  end

  describe "#merge" do
    let!(:problem_merge) do
      ProblemMerge.new(problem, problem_1)
    end
    let!(:notice) { Fabricate(:notice, problem: problem) }
    let!(:notice_1) { Fabricate(:notice, problem: problem_1) }

    it 'delete one of problem' do
      expect do
        problem_merge.merge
      end.to change(Problem, :count).by(-1)
    end

    it 'moves all notices into the merged problem' do
      problem_merge.merge
      expect(Notice.where(problem_id: problem.id).count).to be > 0
      expect(Problem.where(_id: problem_1.id)).to be_empty
    end
  end
end
