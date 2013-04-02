require "spec_helper"
require "json-pointer"

describe JsonPointer do
  let(:hash) do
    {
      :water => ["river", "lake", "ocean", "pond", "everything else"],
      :fire => {
        :water => {
          :wind => "earth"
        },
        :dirt => [
          { :foo => "bar", :hello => "world" },
          { :baz => "biz" }
        ]
      }
    }
  end

  let(:path) { "" }
  let(:path_fragments) { path.split('/') }
  let(:pointer) { described_class.new(hash, path, :symbolize_keys => true) }
  let(:parent_pointer) {
    described_class.new(hash, path_fragments[0..-2].join('/'), :symbolize_keys => true)
  }
  let(:expected_parent_value) {}

  describe "#exists?" do
    shared_examples "a checker method" do
      context "when member exists" do
        it "returns true" do
          expect(pointer.exists?).to be_true
        end
      end

      context "when member exists and is nil" do
        it "returns true" do
          pointer.value = nil
          expect(pointer.exists?).to be_true
        end
      end

      context "when member doesn't exist" do
        let(:hash) { Hash.new }

        it "returns false" do
          expect(pointer.exists?).to be_false
          expect(hash).to eq(Hash.new)
        end
      end
    end

    context "when array index" do
      let(:path) { %(/water/2) }

      it_behaves_like "a checker method"
    end

    context "when in member of array index" do
      let(:path) { %(/fire/dirt/0/hello) }

      it_behaves_like "a checker method"
    end

    context "when array wildcard" do
      let(:path) { %(/fire/dirt/*) }

      it_behaves_like "a checker method"
    end

    context "when in member of array windcard" do
      let(:path) { %(/fire/dirt/*/hello) }

      it_behaves_like "a checker method"
    end

    context "when object member" do
      let(:path) { %(/fire/water/wind) }

      it_behaves_like "a checker method"
    end
  end

  describe "#value" do
    shared_examples "a getter method" do
      context "when member exists" do
        it "returns value of referenced member" do
          expect(pointer.value).to eql(expected_value)
        end
      end

      context "when member doesn't exist" do
        let(:hash) { Hash.new }

        it "returns nil" do
          expect(pointer.value).to be_nil
        end
      end
    end

    context "when array index" do
      let(:path) { %(/water/2) }
      let(:expected_value) { hash[:water][2] }

      it_behaves_like "a getter method"
    end

    context "when in member of array index" do
      let(:path) { %(/fire/dirt/0/hello) }
      let(:expected_value) { hash[:fire][:dirt][0][:hello] }

      it_behaves_like "a getter method"
    end

    context "when array wildcard" do
      let(:path) { %(/fire/dirt/*) }
      let(:expected_value) { hash[:fire][:dirt] }

      it_behaves_like "a getter method"
    end

    context "when in member of array windcard" do
      let(:path) { %(/fire/dirt/*/hello) }
      let(:expected_value) { ["world", nil] }

      it_behaves_like "a getter method"
    end

    context "when object member" do
      let(:path) { %(/fire/water/wind) }
      let(:expected_value) { hash[:fire][:water][:wind] }

      it_behaves_like "a getter method"
    end
  end

  describe "#value=" do
    let(:asymmetric) { false }

    shared_examples "a setter method" do
      context "when parent member exists" do
        it "sets referenced member value" do
          pointer.value = value

          unless asymmetric
            expect(pointer.value).to eql(value)
          end

          if expected_parent_value
            expect(parent_pointer.value).to eql(expected_parent_value)
          end
        end
      end

      context "when parent member doesn't exist" do
        let(:hash) { Hash.new }

        it "sets referenced member value" do
          pointer.value = value
          expect(pointer.value).to eql(value)
        end
      end
    end

    context "when array index" do
      let(:path) { %(/water/2) }
      let(:value) { "swamp" }
      let(:expected_parent_value) { ["river", "lake", value, "ocean", "pond", "everything else"] }

      it_behaves_like "a setter method"
    end

    context "when in member of array index" do
      let(:path) { %(/fire/dirt/0/biz) }
      let(:value) { "baz" }
      let(:expected_parent_value) { { :foo => "bar", :hello => "world", :biz => value } }

      it_behaves_like "a setter method"
    end

    context "when array wildcard" do
      let(:path) { %(/water/*) }
      let(:value) { "baz" }
      let(:asymmetric) { true }
      let(:expected_parent_value) { [value, value, value, value, value] }

      it_behaves_like "a setter method"
    end

    context "when in member of array windcard" do
      let(:path) { %(/fire/dirt/*/gash) }
      let(:value) { "very deep!" }
      let(:asymmetric) { true }
      let(:expected_parent_value) {
        [
          { :gash => value, :foo => "bar", :hello => "world" },
          { :gash => value, :baz => "biz" }
        ]
      }

      it_behaves_like "a setter method"
    end

    context "when object member" do
      let(:path) { %(fire/water/foo) }
      let(:value) { "Foo Bar!" }

      it_behaves_like "a setter method"
    end
  end

  describe "#delete" do
    let(:asymmetric) { false }

    shared_examples "a delete method" do
      context "when parent member exists" do
        it "deletes referenced member" do
          pointer.delete

          unless asymmetric
            expect(pointer.value).to be_nil
          end

          if expected_parent_value
            expect(parent_pointer.value).to eql(expected_parent_value)
          end
        end
      end

      context "when parent member doesn't exist" do
        let(:hash) { Hash.new }

        it "does nothing" do
          pointer.delete
          expect(pointer.value).to be_nil
        end
      end
    end

    context "when array index" do
      let(:path) { %(/water/2) }
      let(:asymmetric) { true }
      let(:expected_parent_value) { ["river", "lake", "pond", "everything else"] }

      it_behaves_like "a delete method"
    end

    context "when in member of array index" do
      let(:path) { %(/fire/dirt/0/foo) }
      let(:expected_parent_value) { { :hello => "world" } }

      it_behaves_like "a delete method"
    end

    context "when array wildcard" do
      let(:path) { %(/water/*) }
      let(:asymmetric) { true }
      let(:expected_parent_value) { [] }

      it_behaves_like "a delete method"
    end

    context "when in member of array windcard" do
      let(:path) { %(/fire/dirt/*/foo) }
      let(:asymmetric) { true }
      let(:expected_parent_value) {
        [
          { :hello => "world" },
          { :baz => "biz" }
        ]
      }

      it_behaves_like "a delete method"
    end

    context "when object member" do
      let(:path) { %(fire/water/foo) }

      it_behaves_like "a delete method"
    end
  end
end
